exports.name = "json-rpc"
exports.author = "Niklas Kühtmann"
exports.version = "0.0.1"

local json = require("json")
local httpclient = require("httpclient")


exports.request = function(options, cb)
	options.headers = options.headers or {}

	local str = ""
	if options.data then
		str = json.encode({params = options.data})
		options.data = nil
	end

	options.headers["Content-Type"] = "application/json"
	options.headers["Accept"] = "application/json"
	options.headers["Content-Length"] = #str
	options.method = "POST"

	local f = function(err, out, res)
		if err then return cb(err) end

		local out = out and json:decode(out)

		if out.error then
			return cb(out.error.data.message)
		end

		cb(nil, out, res) 
	end

	local req = httpclient.request(options, f)

	req:write(str)
	req:done(str)

end