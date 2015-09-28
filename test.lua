local DigitalPin = require("./GPIO")
local timer = require("timer")

pins = {15, 13, 36, 33, 12, 11, 37, 38}

for k1,v1 in ipairs(pins) do
	local pin  = DigitalPin:new({pin = v1, mode = "w"})
	pin:on("error", function(error)
		p(error)
	end)
	pin:on("close", function(pinNum)
		p("Pin", pinNum, "Closed successfully!")
	end)
	pin:on("open", function( )
		p("[Success] Pin", v1, "Opened!!!")
		if v1 > 30 then
			pin:setHigh()
		end
	end)
	pin:connect()
	_G["pin" .. v1] = pin
end

function up()
	pin15:setHigh()
	pin13:setLow()
	pin12:setHigh()
	pin11:setLow()
end

function back( )
	pin15:setLow()
	pin13:setHigh()
	pin12:setLow()
	pin11:setHigh()
end

function stop( )
	pin15:setLow()
	pin13:setLow()
	pin12:setLow()
	pin11:setLow()	
end

function cleanup( )
	pin11:close()
	pin12:close()
	pin13:close()
	pin15:close()
	pin33:close()
	pin36:close()
	pin37:close()
	pin38:close()
end

function left( )
	pin15:setHigh()
	pin13:setLow()
	pin12:setLow()
	pin11:setHigh()
end

function right( )
	pin15:setLow()
	pin13:setHigh()
	pin12:setHigh()
	pin11:setLow()
end

timer.setTimeout(5000, function( )
	stop()
	cleanup()	
end)

timer.setTimeout(3000, function ( )
	left()
end)

