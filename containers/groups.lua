
--[[    
    LuauProgrammer
    groups.lua
    API for ROBLOX's group API
]]

local module = {}
local token = require('./authentication').AuthenticationToken
local http = require('coro-http')
local json = require('json')

module.HandleJoinRequest = function(userID,groupID)
    local res, body = http.request("POST", "https://groups.roblox.com/v1/groups/"..groupID.."/join-requests/users/"..userID, {{"Content-Type", "text/json"},{"Content-Length", "0"}, {"X-CSRF-TOKEN", X_CSRF_TOKEN}, {"Cookie", token}})
    if res.code ~= 200 then
        return nil
    end
    return json.decode(body)
end

module.GetGroupInformation = function(groupID)
    local res, body = http.request("GET", "https://groups.roblox.com/v1/groups/"..groupID)
    if res.code ~= 200 then
        return nil
    end
    return json.decode(body)
end

return module