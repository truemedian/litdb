local toast = require 'SuperToast'

---@type Command
local ping = toast.Command('ping')

ping:execute(function(msg, _, client)
   local new = client:reply(msg, 'pinging...')

   new:setContent('pong! ' .. math.random(50, 2000) .. 'ms')
end)

return ping