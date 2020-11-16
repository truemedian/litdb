---@type SuperToast
local toast = require './init'

toast.dotenv.config()

---@type SuperToastClient
local client = toast.Client(process.env.TOKEN, {},
                            {gatewayFile = './private/gateway.json', logFile = './private/discordia.log'})

---@type Command
local cmd = toast.Command

local ping = cmd('ping'):execute(function(msg)
   msg:reply 'pong!'
end)

client:addCommand(ping)

client:login()
