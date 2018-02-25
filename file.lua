--[[lit-meta
name = 'Kogiku/cleverbot'
version = '1.0.1'
homepage = 'https://github.com/Kogiku/cleverbot_luvit'
description = 'Simple implementation of the CleverBot API for Luvit.'
dependencies = {
	'creationix/coro-http',
	'luvit/querystring',
	'luvit/json'
}
tags = {'cleverbot', 'api'}
license = 'MIT'
author = 'Kogiku'
]]

-- API key: https://www.cleverbot.com/api/

local http = require('coro-http')
local urlencode = require('querystring').urlencode
local JSON = require('json')

local cleverbot = {}
cleverbot.__index = cleverbot

function cleverbot.newCState(init)
	local self = setmetatable({}, cleverbot)
	self.cState = init
	return self
end

function cleverbot.setCState(self, new) self.cState = new end
function cleverbot.getCState(self) return self.cState end

cState = cleverbot.newCState('')

function cleverbot.buildURL(text, apiKey)
	local URL_base = 'http://www.cleverbot.com/getreply?key=%s'
	local URL_input = '&input=%s'
	local URL_cState = "&cs=%s"
	local CS = cState
	return string.format(URL_base, apiKey)
	..string.format(URL_input, urlencode(text))
	..string.format(URL_cState, CS:getCState())
end

function cleverbot.talk(text, apiKey, cStateBool)
	local head,body = http.request('GET', cleverbot.buildURL(text, apiKey))
	if head.code == 200 then
		local json = JSON.parse(body)
		local CS = cState
		if cStateBool == false then
			CS:setCState('')
		else CS:setCState(json.cs) end
		return json.output
	elseif head.code ~= nil then
		local errcode = '!! CleverBot error: '..head.code
		return errcode
	else
		local nilerr = '!! CleverBot error: unknown'
		return nilerr
	end
end

return cleverbot
