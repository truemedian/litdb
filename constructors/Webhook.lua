---@diagnostic disable: undefined-field

local Webhook = {}
Webhook.__index = Webhook
Webhook.__metatable = false
Webhook.Class = "Webhook"

local WHURLS= {
	"https://discord.com/api/webhooks/%d+/.+",
	"https://discordapp.com/api/webhooks/%d+/.+"
}

local _scanparam = require("../util/ScanParam")
local _log = require("../util/Log")
local json = require("json")
local http = require("coro-http")

function Webhook.new(url)
    _scanparam({"url", url}, {"string"}, true, true)

    local matched = false
	
	for index, pattern in ipairs(WHURLS) do
		if (string.match(url, pattern)) then
			matched = true
			break
		end
	end
	
	if not matched then
		error("Please provide a valid Discord Webhook URL.")
	end

    local Hook = {}
    Hook.URL = tostring(url)

    _log(1, "Created webhook object")

    return setmetatable(Hook, Webhook)
end

function Webhook:Send(Message, Timeout)
    _scanparam({"Message", Message}, {"table", "Message"}, true, true)
    _scanparam({"Timeout", Timeout}, {"number"}, false, true)

    if Timeout == nil then Timeout = 5 end

    local Seconds = Timeout * 1000

    local rawdata = json.encode(Message.rawdata or Message)

    local Headers = {
        {"Content-Length", tostring(#rawdata)},
        {"Content-Type", "application/json"}
    }

    coroutine.wrap(function()
        _log(1, "Sending data...")

        local res, body = http.request("POST", self.URL, Headers, rawdata, Seconds)

        if res.code < 200 or res.code >= 300 then
            _log(2, "HTTP Error: %d %s", res.code, res.reason)
            return
        end

        _log(1, "Sended data.")
    end)()

    return self
end

Webhook.__call = function(_, ...) return Webhook.new(...) end

return setmetatable(Webhook, Webhook)