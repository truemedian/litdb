---@type SuperToast
local toast = require 'SuperToast'
local fs = require 'fs'

toast.dotenv.config()

local stringx = toast.stringx

---@type SuperToastClient
local client = toast.Client(process.env.TOKEN, {
   prefix = 'sd;'
}, {
   dateTime = '%b, %d',
   logFile = './private/discordia.log',
   gatewayFile = './private/gateway.json'
})

client:addCommand(toast.help)

rawset(client._logger, "log", require './utils/logger')
client._logger._startTime = os.time()

print(require('./utils/colorBlend')([[
   _____            _      _     _____              
  / ____|          (_)    | |   |  __ \             
 | (___   _____   ___  ___| |_  | |  | | __ _ _ __  
  \___ \ / _ \ \ / / |/ _ \ __| | |  | |/ _` | '_ \ 
  ____) | (_) \ V /| |  __/ |_  | |__| | (_| | | | |
 |_____/ \___/ \_/ |_|\___|\__| |_____/ \__,_|_| |_|
]], 0xfc5c65, 0x45aaf2), '\n')

for _, file in pairs(fs.readdirSync('./commands')) do
   local path

   if stringx.endswith(file, '.lua') then
      path = './commands/' .. file:sub(0, #file - 4)
   elseif fs.lstatSync('./commands/' .. file).type == 'directory' then
      path = './commands/' .. file
   end

   local succ, err = pcall(function()
      client:addCommand(require(path))
   end)

   if not succ then
      client:error('Failed loading command: %s', err)
   else
      client:info('Loaded: %s', file)
   end
end

client:login()