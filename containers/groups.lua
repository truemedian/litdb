
--[[    
    LuauProgrammer
    groups.lua
    API for ROBLOX's group API
]]

--//Require any modules and define variables

local module = {}

local http = require('coro-http')
local decode = require('json').decode
local encode = require('json').encode

module.HandleJoinRequest = function(userID,groupID)
    local res, body = http.request("POST", "https://groups.roblox.com/v1/groups/"..groupID.."/join-requests/users/"..userID, {{"Content-Type", "text/json"},{"Content-Length", "0"}, {"X-CSRF-TOKEN", X_CSRF_TOKEN}, {"Cookie", "_eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJiOWRmZDY0Ni04MTdkLTRlODUtOWQ0MS02ZGExMjk5ZDhkNjYiLCJzdWIiOjk4MDYzODY5Nn0.RBMSpTQyhJXaTakVFfFtUA92pU_r6zfwA6XxZneCfkM"}})
    if res.code ~= 200 then
        print(res.reason)
        return nil
    end
    return decode(body)
end

module.GetGroupInformation = function(groupID)
    local res, body = http.request("GET", "https://groups.roblox.com/v1/groups/"..groupID)
    if res.code ~= 200 then
        return nil
    end
    return decode(body)
end

return module