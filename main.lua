local request = require "coro-http".request
local decode = require "json".decode
local endpoints = require "./endpoints"
local format = string.format

local api = {}
--stop snooping around . . .
return api
