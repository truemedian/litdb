
--[[    
    LuauProgrammer
    users.lua
    API for ROBLOX's user API
]]

local module = {}

local http = require('coro-http')
local decode = require('json').decode
local encode = require('json').encode

module.GetUserByID = function(userID)
    local res, body = http.request("GET", "https://users.roblox.com/v1/users/"..userID)
    if res.code ~= 200 then
        return nil
    end
    return decode(body)
end

module.GetUserByName = function(name)
    local params = '{ \"usernames\": [ '..encode(name)..' ], \"excludeBannedUsers\": true}'
    local res, body = http.request("POST", "https://users.roblox.com/v1/usernames/users/", {{"Content-Type","text/json"}}, params)
    if res.code ~= 200 then
        return nil
    end
    local data
    for i,v in pairs(decode(body)) do --Legit a fucking terrible idea
        data = v
        for i,v in pairs(data) do
            data = v
        end
    end
    if data.id ~= nil then
        return module.GetUserByID(data.id)
    end
    return nil
end

return module