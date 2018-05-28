local htt = {}
local json = require("./json")
local http = require("coro-http")

function htt:getJson(link)
	coroutine.wrap(function()
		local res, jsonToDecode = http.request("GET", link)
		local id = json.decode(jsonToDecode)

		return id
	end)	
end

function htt:get(link)
	coroutine.wrap(function()
		local res, id = http.request("GET", link)

		return id
	end)	
end