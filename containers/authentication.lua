--[[    
    LuauProgrammer
    authentication.lua
    Authenticates a user/deauthenticates them
]]

local module = {}
local token = require('./authentication').AuthenticationToken
local http = require('coro-http')
local json = require('json')

module.AuthenticationToken = nil

module.Authenticate = function(token)
    module.AuthenticationToken = '.ROBLOSECURITY='..token
end

module.Deauthenticate = function()
    if module.AuthenticationToken ~= nil then
        module.AuthenticationToken = nil
    end
end

return module