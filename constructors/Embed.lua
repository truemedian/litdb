local Embed = {}
Embed.__index = Embed
Embed.__metatable = false
Embed.Class = "Embed"

local Color = require("./Color")
local _scanparam = require("../util/ScanParam")
local _scanurl = require("../util/ScanURL")
local _typeof = require("../util/TypeOf")
local _log = require("../util/Log")

function Embed.new(data)
    _scanparam({"data", data}, {"nil", "table"}, false, true)

    local emb = data or {}
    emb.rawdata = {}

    _log(1, "Created embed object.")

    return setmetatable(emb, Embed)
end

function Embed:SetTitle(title)
    _scanparam({"title", title}, {"string"}, true, true, {1, 256})

    self.rawdata.title = title

    _log(1, "Setted embed title.")

    return self
end

function Embed:SetDescription(description)
    _scanparam({"description", description}, {"string"}, true, true, {1, 2048})

    self.rawdata.description = description

    _log(1, "Setted embed description.")

    return self
end

function Embed:SetColor(color)
    _scanparam({"color", color}, {"string", "Color"}, true, true)

    if type(color) == "table" then
        color = color:ToHex()
    elseif _typeof(color) == "string" and string.sub(color, 1, 1) == "#" then
        color = string.gsub(color, "#", "0x")
    end

    self.rawdata.color = tonumber(color)

    _log(1, "Setted embed color.")

    return self
end

function Embed:AddField(name, value, inline)
    _scanparam({"name", name}, {"string"}, true, true, {1, 256})
	_scanparam({"value", value}, {"string"}, true, true, {1, 1024})
	_scanparam({"inline", inline}, {"boolean"}, false, true)

    if not self.rawdata.fields then
        self.rawdata.fields = {}
    end

    self.rawdata.fields[#self.rawdata.fields + 1] = {
        name = name,
        value = value,
        inline = inline or false
    }

    _log(1, "Added field. [Table Pos: %d]", #self.rawdata.fields)

    return self
end

function Embed:AddFields(...)
    _log(1, "Adding %d fields.", #{...})

    for _, field in pairs{...} do
		_scanparam({"field", field}, {"table"}, false, true)
		self:AddField(field.name, field.value, field.inline)
	end

    _log(1, "Added %d fields.", #{...})

	return self
end

function Embed:SetHeader(name, icon_url, url)
    _scanparam({"name", name}, {"string"}, true, true, {1, 256})
    _scanparam({"icon_url", icon_url}, {"string"}, false, true)
    _scanparam({"url", url}, {"string"}, false, true)

    _scanurl(icon_url)
    _scanurl(url)

    self.rawdata.author = {
        name = name,
        icon_url = icon_url,
        url = url
    }

    _log(1, "Setted embed header.")

    return self
end

function Embed:SetFooter(text, icon)
    _scanparam({"text", text}, {"string"}, true, true, {1, 2048})
    _scanparam({"icon", icon}, {"string"}, false, true)

    self.rawdata.footer = {
        text = text,
        icon_url = icon
    }

    _log(1, "Setted embed footer.")

    return self
end

function Embed:SetTimestamp(timestamp)
    _scanparam({"timestamp", timestamp}, {"number"}, false, true)

    timestamp = timestamp or os.time()

	local offset = os.date("%z", timestamp)
	local operator, value = string.match(offset, "(%p)(%d+)")

	offset = tonumber(operator .. (value / 100)) * 3600
	timestamp = timestamp - offset

	self.rawdata.timestamp = os.date("%Y-%m-%dT%H:%M:%SZ", timestamp)

    _log(1, "Setted embed timestamp.")

    return self
end

function Embed:SetThumbnail(url)
    _scanparam({"url", url}, {"string"}, true, true)

    _scanurl(url)

    self.rawdata.thumbnail = {
        url = url,
        proxy_url = url
    }

    _log(1, "Setted embed thumbnail.")

    return self
end

function Embed:SetImage(url)
    _scanparam({"url", url}, {"string"}, true, true)

    _scanurl(url)

    self.rawdata.image = {
        url = url,
		proxy_url = url,
    }

    _log(1, "Setted embed image.")

    return self
end

Embed.__call = function(_, ...) return Embed.new(...) end

return setmetatable(Embed, Embed)