--[[    
    LuauProgrammer
    authentication.lua
    Authenticates a user/deauthenticates them
]]

local module = {}

local http = require('coro-http')
local decode = require('json').decode
local encode = require('json').encode

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