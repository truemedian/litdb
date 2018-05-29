local htt = {}
local json = require("./json")
local http = require("coro-http")



function htt:get(link)
	return coroutine.wrap(function()
		local res, id = http.request("GET", link)
		print(id)
		return id
	end)()
end

function htt:getJson(link)
	return coroutine.wrap(function()
		local res, id = http.request("GET", link)

		id = json.decode(id)
		return id
	end)()
end

return htt