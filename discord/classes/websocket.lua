local core = require('core')
local json = require('json')
local ws = require('coro-websocket')

local Websocket = core.Object:extend()

function Websocket:initialize(gateway)
	local options = ws.parseUrl(gateway)
	self.res, self.read, self.write = ws.connect(options)
end

function Websocket:send(payload)
	local message = {opcode = 1, payload = json.encode(payload)}
	return self.write(message)
end

function Websocket:receive()
	local message = self.read()
	return json.decode(message.payload)
end

return Websocket