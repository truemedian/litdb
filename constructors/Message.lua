local Message = {}
Message.__index = Message
Message.__metatable = false
Message.Class = "Message"

local _scanparam = require("../util/ScanParam")
local _scanurl = require("../util/ScanURL")
local _typeof = require("../util/TypeOf")
local _log = require("../util/Log")

function Message.new(data)
    _scanparam({"data", data}, {"nil", "table"}, false, true)

    local msg = {}
    msg.rawdata = data or {}

    _log(1, "Created message object.")

    return setmetatable(msg, Message)
end

function Message:SetContent(content)
   _scanparam({"content", content}, {"string"}, true, true, {1, 2000})

   self.rawdata.content = content

   _log(1, "Setted message content")

   return self
end

function Message:SetUsername(username)
    _scanparam({"username", username}, {"string"}, true, true, {1, 80})

    self.rawdata.username = username

    _log(1, "Setted message username")

    return self
end

function Message:SetAvatarURL(url)
    _scanparam({"url", url}, {"string"}, true, true)

    _scanurl(url)

    self.rawdata.avatar_url = url

    _log(1, "Setted message avatar URL")

    return self
end

function Message:AddEmbed(embed)
    _scanparam({"embed", embed}, {"table", "Embed"}, true, true)

    if not self.rawdata.embeds then
        self.rawdata.embeds = {}
    end

    assert((#self.rawdata.embeds + 1) <= 10, "You can only exceed 10 embed per message.")

    table.insert(self.rawdata.embeds, embed.rawdata or embed)

    _log(1, "Added embed. [Table Pos: %d]", #self.rawdata.embeds)

    return self
end

function Message:AddEmbeds(...)
    local embeds = {...}

    _scanparam({"embeds", embeds[1]}, {"array", "table", "Embed"}, true, true)

    if _typeof(embeds[1]) == "array" then
        embeds = embeds[1]
    end

    _log(1, "Adding "..#embeds.." embeds.")
    for _, embed in next, embeds do
        _scanparam({"embed", embed}, {"table", "Embed"}, false, true)
        self:AddEmbed(embed)
    end

    _log(1, "Added "..#embeds.." embeds.")

    return self
end

Message.__call = function(_, ...) return Message.new(...) end

return setmetatable(Message, Message)