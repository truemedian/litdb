local json = require('json')
local http = require('coro-http')

local api = require('../constants/api')
local package = require('../package')


function api.request (config)
	if not config or not config.path then return end
	local method = (config.type or config.method or 'GET'):upper()
	local data = (config.data and json.encode(config.data))
	local response, received = http.request(
		method,
		api.base..'/'..config.path,
		{
			{
				'Content-Type',
				'application/json',
			},
			{
				'User-Agent',
				package.name..' ('..package.homepage..', '..package.version..')',
			},
			{
				'Authorization',
				config.token,
			},
		},
		data
	)
	return json.decode(received)
end

return api