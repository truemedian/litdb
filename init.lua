_G.json = require("json")
_G.http = require("coro-http")
_G.query = require("querystring")
_G.class = require("class")
local Get = require("Get")
local Post = require("Post")
local Delete = require("Delete")
local Error = require("Error")

_G.Request = function(mode, url, rest)
	url = url or "https://api.paste.ee/v1/"
	local er, body = http.request(mode, url, nil, rest)
	if tostring(er.code) ~= "200" then
		error(er.code..": "..Error(er.code))
		return
	end
	return body
end

_G.AdaptToUrl = function(index)
	local ind1 = string.gsub(index, "\n", "%%0A")
	local ind2 = string.gsub(ind1, "\r", "%%09")
	return ind2
end



return {
	get = Get,
	post = Post,
	delete = Delete
}
