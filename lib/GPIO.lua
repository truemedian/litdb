--[[
	-- GPIO for luvit
	-- a Raspberry PI GPIO Lib for Luvit 

	Title: GPIO.lua
	author: Name: Cyril Hou
	author: Github: cyrilis
	author: Twitter: cyr1l
	author: Email: houshoushuai@gmail.com
	created_at: 2015-09-13 04:23:22
--]]

local FS = require("fs");
local timer = require("timer")
local Emitter = require("core").Emitter
local helper = require("./helper")

local GPIO_PATH = "/sys/class/gpio"

local GPIO_READ = "in"
local GPIO_WRITE = "out"

local DigitalPin = Emitter:extend()

module.exports = DigitalPin

local cpuInfo = FS.readFileSync("/proc/cpuinfo")

local rev = 2

if cpuInfo then 
	local cpuInfoArray = helper.split(cpuInfo, "\n")
	for _,v in ipairs(cpuInfoArray) do
		local idx = string.find(v, "revision", 1)
		if idx and idx >= 0 then
			local revNum = tonumber(helper.split(v, ":")[2], 16) 
			if revNum and revNum < 3 then
				rev = 1
			end
			break
		end
	end
end

local pinMapping = {
	["3"] = "0",
	["5"] = "1",
	["7"] = "4",
	["8"] = "14",
	["10"] =  "15",
	["11"] =  "17",
	["12"] =  "18",
	["13"] =  "21",
	["15"] =  "22",
	["16"] =  "23",
	["18"] =  "24",
	["19"] =  "10",
	["21"] =  "9",
	["22"] =  "25",
	["23"] =  "11",
	["24"] =  "8",
	["26"] =  "7",

	--  Model A+ and Model B+ pins
	["29"] =  "5",
	["31"] =  "6",
	["32"] =  "12",
	["33"] =  "13",
	["35"] =  "19",
	["36"] =  "16",
	["37"] =  "26",
	["38"] =  "20",
	["40"] =  "21"
}

if rev == 2 then
	pinMapping["3"] = "2";
	pinMapping["5"] = "3";
	pinMapping["13"] = "27";
end

function DigitalPin:initialize( opts )
	self.pinNum = pinMapping[tostring(opts.pin)]
	self.status = "low"
	self.ready = false
	self.mode = opts.mode
end

function DigitalPin:connect( mode )
	if self.mode == null then
		self.mode = mode
	end
	local that = self
	local exists = FS.existsSync(self:_pinPath())
	if exists then
		that:_openPin()
	else
		that:_createGPIOPin()
	end
end

function DigitalPin:close( )
	local that = self
	FS.writeFile(self:_unexportPath(), self.pinNum, function( err )
		that:_closeCallback(err)
	end)
end

function DigitalPin:closeSync( )
	fs.writeFileSync(self:_unexportPath(), self.pinNum)
	self:_closeCallback(false)
end

function DigitalPin:digitalWrite( value )
	if self.mode ~= "w" then
		self:_setMode("w")
	end

	self.status = (value == 1 and "high" or "low")

	local that = self
	FS.writeFile(self:_valuePath(), value, function ( err )
		if err then
			local str = "Error occored while writing value"
			str = str .. value .. " to pin " .. that.pinNum
			that:emit("error", str)
		else
			that:emit("digitalWrite")
		end
	end)
end

function DigitalPin:digitalRead( interval )
	if self.mode ~= 'r' then
		self:_setMode("r")
	end

	local that = self
	timer.setInterval(interval, function ( )
		FS.readFile(that:_valuePath(), function ( err, data )
			if err then
				local error = "Error occurred while reading from pin " .. that.pinNum
				that:emit("error", error)
			else
				local readData = tonumber(tostring(data))
				that:emit("digitalRead", readData)
			end
		end)
	end)
end

function DigitalPin:setHigh( )
	self:digitalWrite(1)
end

function DigitalPin:setLow( )
	self:digitalWrite(0)
end

function DigitalPin:toggle( )
	if selt.status == 'low' then
		self:setHigh()
	else
		self:setLow()
	end
end

function DigitalPin:_createGPIOPin( )
	local that = self
	FS.writeFile(self:_exportPath(), self.pinNum, function ( err )
		if err then 
			that:emit("error", "Error whil createing pin files")
		else
			that:_openPin()
		end
	end)
end

function DigitalPin:_openPin( )
	self:_setMode(self.mode, true)
	self:emit("open")
end

function DigitalPin:_closeCallback( err )
	if err then
		self:emit("error", "Error while close pin files" .. self.pinNum)
	else
		self:emit("close", self.pinNum)
	end
end

function DigitalPin:_setMode( mode, emitConnect )
	if emitConnect == nil then
		emitConnect = false
	end

	self.mode = mode

	local data = GPIO_READ
	if mode == 'w'
		then data = GPIO_WRITE
	end
	local that = self
	FS.writeFile(self:_directionPath(), data, function( )
		that:_setModeCallback(err, emitConnect);
	end)
end

function DigitalPin:_setModeCallback( err, emitConnect )
	if err then 
		return self:emit("error", "Setting up pin direction failed")
	end

	self.ready = true

	if emitConnect then
		self:emit("connect", self.mode)
	end
end

function DigitalPin:_directionPath( )
	return self:_pinPath() .. "/direction"
end

function DigitalPin:_valuePath()
	return self:_pinPath() .. "/value"
end

function DigitalPin:_pinPath( )
	return GPIO_PATH .. "/gpio" .. self.pinNum
end

function DigitalPin:_exportPath( )
	return GPIO_PATH .. "/export"
end

function DigitalPin:_unexportPath( )
	return GPIO_PATH .. "/unexport"
end
