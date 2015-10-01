exports.name = "httpclient"
exports.author = "Niklas Kühtmann"
exports.version = "0.0.1"

local http = require("http")

exports.request = function(options, cb)
	local output = ""
	options.headers = options.headers or {}
	options.headers["User-Agent"] = options.headers["User-Agent"] or "ZED/httpclient (odoo)"
	options.method = options.method or "GET"
	local req = http.request(options, function (res)
		res:on("error", function(err)
			cb(tostring(err))
		end)

		res:on("data", function (chunk)
			output = output .. chunk
		end)

		res:on("end", function ()
			res:destroy()
			cb(nil, output, res)
		end)
	end)

	req:on("error", function(err)
		cb(tostring(err))
	end)

	return req
end