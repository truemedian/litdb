
--[[    
    LuauProgrammer
    games.lua
    API for ROBLOX's game API
]]

local module = {}
local token = require('./authentication').AuthenticationToken
local http = require('coro-http')
local json = require('json')

module.GetUserByID = function(gameID)
    local res, body = http.request("GET", "https://games.roblox.com/v1/games/multiget-place-details?placeIds="..gameID)
    if res.code ~= 200 then
        return nil
    end
    return json.decode(body)
end

return module

