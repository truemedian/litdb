local discordia = require("discordia")
local json = require("json")
local fs = require("fs")
local corohttp = require("coro-http")
local base64 = require("base64")
local CommandHandlerClass = require("./Core/CommandHandler")
local client = discordia.Client()
local libs = {json = json, fs = fs, corohttp = corohttp, base64 = base64}

local function ReadFile(name)
    local file = fs.openSync(name, "r+")
    local text = fs.readSync(file)
    fs.closeSync(file)

    return text
end

local function WriteFile(name, text)
    local file = fs.openSync(name, "w+")
    fs.writeSync(file, -1, text)
    fs.closeSync(file)
end

libs.WriteFile = WriteFile
libs.ReadFile = ReadFile

local Config = json.decode(ReadFile("Config.json"))
local Data = json.decode(ReadFile("Data.json"))

assert(Config, "Config is missing?")
assert(Data, "Data is missing?")
local CommandHandler = CommandHandlerClass.new(Config, discordia, client, Data, libs) -- gives cmd handler stuff it needs :)

local function botReady()
    print'Ready!'
end

local function messageSent(message)
    CommandHandler:handleInput(message) -- does the command handling stuffs
end



client:on('ready', botReady)
client:on('messageCreate', messageSent)
client:run("Bot "..Config.Token)



