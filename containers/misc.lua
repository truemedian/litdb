local request = require "coro-http".request
local decode = require "json".decode
local endpoints = require "../endpoints"
local format = string.format

local api = {}

function api:getIdFromName(name, callback)
    if type(name) ~= "string" then return error(name.." is not a string.") end

    coroutine.wrap(function()
        local _,body = request("GET", format(endpoints.username, name))
        local info = decode(body).Id

        callback(info)
    end)()
end

return api
