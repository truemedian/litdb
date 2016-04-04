local json = require('json')
local websocket = require('coro-websocket')

local Websocket = class()

function Websocket:__init(gateway)
	local options = websocket.parseUrl(gateway)
	self.res, self.read, self.write = websocket.connect(options)
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
