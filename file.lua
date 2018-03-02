--[[lit-meta
name = 'Kogiku/cleverbot'
version = '1.0.3'
homepage = 'https://github.com/Kogiku/cleverbot_luvit'
description = 'Simple CleverBot API Wrapper for Luvit.'
dependencies = {
	'creationix/coro-http',
}
tags = {'cleverbot', 'api'}
license = 'MIT'
author = 'Kogiku'
]]

local http = require('coro-http')
local urlencode = require('querystring').urlencode
local JSON = require('json')

local errors = {
	['err'] = '!! CleverBot error ',
	['401'] = ' : Unauthorised due to missing or invalid API key',
	['404'] = ' : API not found',
	['413'] = ' : Request too large, please limit to 64Kb',
	['502'] = ' : Unable to get reply from API server, please contact CleverBot Support',
	['503'] = ' : Too many requests from a single IP address or API key',
}

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
	local URL_base = 'http://www.cleverbot.com/getreply?wrapper=cleverbot_luvit&key=%s'
	local URL_input = '&input=%s'
	local URL_cState = "&cs=%s"
	local CS = cState
	return string.format(URL_base, apiKey)
	..string.format(URL_input, urlencode(text))
	..string.format(URL_cState, CS:getCState())
end

function cleverbot.talk(text, apiKey, cStateBool)
	local head, body = http.request('GET', cleverbot.buildURL(text, apiKey))
	local json = JSON.parse(body)
	local CS = cState
	if head.code == 200 then
		if cStateBool == false then
			CS:setCState('')
		else CS:setCState(json.cs) end
		return json.output
	elseif head.code == 401 then
		return errors.err..head.code..errors['401']
	elseif head.code == 404 then
		return errors.err..head.code..errors['404']
	elseif head.code == 413 or head.code == 414 then
		return errors.err..head.code..errors['413']
	elseif head.code == 502 or head.code == 504 then
		return errors.err..head.code..errors['502']
	elseif head.code == 503 then
		return errors.err..head.code..errors['503']
	elseif head.code then
		return errors.err..head.code
	else return errors.err..' : unknown' end
end

return cleverbot
