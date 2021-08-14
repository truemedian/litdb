--[[    
    LuauProgrammer
    authentication.lua
    API for ROBLOX's authentication API
]]

local module = {}

local http = require('coro-http')
local decode = require('json').decode
local encode = require('json').encode



return module