local timer = require('timer')
local json = require('json')
local WebSocket = require('coro-websocket')

local api = require('./api')
local class = require('../classes/class')
local constants = require('../constants')
local package = require('../package')
--
local Socket = class()

function Socket:__constructor (client)
	self.client = client
	self.settings = client.settings.socket
	self.status = constants.status.IDLE
	client:on(
		constants.events.READY,
		function(data)
			self.timer = timer.setInterval(
				data.heartbeat_interval,
				function()
					self:send(
						{
							op = constants.OPcodes.HEARTBEAT,
							d = self.sequence,
						}
					)
				end
			)
		end
	)
end

function Socket:send (what)
	if not self.write then return end
	coroutine.wrap(
		function()
			self.write(
				{
					opcode = 1,
					payload = json.encode(what),
				}
			)
		end
	)()
end

function Socket:connect ()
	if not self.gateway then
		self.gateway = api.request(
			{
				type = 'GET',
				path = 'gateway',
			}
		).url..'/'
	end
	print('Connecting.')
	local url = WebSocket.parseUrl(self.gateway)
	_, self.read, self.write = WebSocket.connect(url)
	--
	if not self.read or not self.write then
		print('Unable to connect.')
		return
	end
	--
	print('Connected, identifying.')
	self:send(
		{
			op = constants.OPcodes.IDENTIFY,
			d =
			{
				token = self.token,
				properties =
				{
					['$os'] = package.name,
					['$device'] = package.name,
					['$browser'] = '',
					['$referrer'] = '',
					['$referring_domain'] = package.homepage,
				},
				compress = false,
				large_threshold = self.settings.large_threshold,
			},
		}
	)
	--
	self:listen()
end

function Socket:listen () -- reading
	print('Listening.')
	while true do
		if not self.read then return end
		local read = self.read()
		if read and read.payload then
			local data = json.decode(read.payload)
			if data.op == constants.OPcodes.DISPATCH then
				self.sequence = data.s
				self.client:dispatchEvent(data.t, data.d)
			end
		else
			timer.clearInterval(self.timer)
			print('Disconnected.')
			break
		end
	end
end

return Socket