local json = require("json")
local http = require("coro-http")

local myKey = ""

local function Request(url, rest)
	url = url or "http://paste.ee/api"
	local er, body = http1.request("POST", url.."?"..rest)
	if tostring(er.code) == "404" then
		error("Error code: "..er.code.." at POST request.")
		return "Error"
	end
	return body
end

-- Using default parameters
local function Post(code)
	local description = description or "Lua"
	local language = language or "lua"
	local paste = code or ""
	local encrypted = encrypted or ""
	local expire = expire or ""

	local parse = "key="..myKey.."&description="..description.."&language="..language.."&encrypted="..encrypted.."&expire="..expire.."&paste="..paste

	local body = Request(EncodeUri(parse))

	if body == "Error" then return end

	local bodyToLua = json.parse(body)
	local links = bodyToLua.paste

	return links.raw, links.link, links.download, links.min
end


-- Not using default parameters
local function Post2(description, language, code, encrypted, expire)
	local description = description or "Lua"
	local language = language or "lua"
	local paste = code or ""
	local encrypted = encrypted or ""
	local expire = expire or ""

	local parse = "key="..myKey.."&description="..description.."&language="..language.."&encrypted="..encrypted.."&expire="..expire.."&paste="..paste

	local body = Request(EncodeUri(parse))
	local bodyToLua = json.parse(body)
	
	if body == "Error" then return end
	local links = bodyToLua.paste

	return links.raw, links.link, links.download, links.min
end
