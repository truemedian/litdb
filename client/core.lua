local enum = require("../utils/enum")
local websocket = require("./websocket")
local Emitter = require("../utils/emitter")
local http = require("coro-http")
local json = require("json")

local ev = Emitter:get("Client")

local base_url = "https://discord.com/api"

return function(token)
    return {
        login = function(status)
            if not status then
                status = "online"
            end

            websocket:run(token, status)
        end,
        onReceive = ev.on,
        GetChannel = function(self, id)
            local i, gbory
            local _, body
            local success, result = pcall(function()
                _, body = http.request("GET", base_url.."/channels/"..id, {{"Authorization", "Bot "..token}, {"Content-Type", "application/json"}})
            end)

            local channel = json.parse(body)
            local channelType = channel.type

            local scs, err = pcall(function()
                i, gbory = http.request("GET", base_url.."/guilds/"..channel.guild_id, {{"Authorization", "Bot "..token}, {"Content-Type", "application/json"}})
            end)
            local guild = json.parse(gbory)

            if not scs then
                print(body)
            end

            if not success then
                print(body)
            end

            guild["icon"] = "https://cdn.discordapp.com/icons/"..guild.id.."/"..guild.icon
            if guild.banner then
                guild["banner"] = "https://cdn.discordapp.com/banners/"..guild.id.."/"..guild.banner
            end
            guild["splash"] = nil
            guild["icon_hash"] = nil
            guild["discovery_splash"] = nil
            guild["owner"] = nil
            guild["permissions"] = nil
            guild["region"] = nil
            guild["default_message_notifications"] = nil
            guild["explicit_content_filter"] = nil
            guild["system_channel_flags"] = nil
            guild["vanity_url_code"] = nil
            guild["boost_tier"] = guild["premium_tier"]
            guild["premium_tier"] = nil
            guild["boost_count"] = guild["premium_subscription_count"]
            guild["premium_subscription_count"] = nil
            guild["locale"] = guild["preferred_locale"]
            guild["preferred_locale"] = nil
            guild["member_count"] = nil

            if channelType == 0 then
                channel["ChannelType"] = enum.ChannelType.GuildTextChannel
            elseif channelType == 1 then
                channel["ChannelType"] = enum.ChannelType.DM
            elseif channelType == 2 then
                channel["ChannelType"] = enum.ChannelType.GuildVoiceChannel
            elseif channelType == 3 then
                channel["ChannelType"] = enum.ChannelType.DMGroup
            elseif channelType == 4 then
                channel["ChannelType"] = enum.ChannelType.Category
            elseif channelType == 5 then
                channel["ChannelType"] = enum.ChannelType.AnnouncementChannel
            end
            channel["type"] = nil
            channel["guild_id"] = nil
            channel["guild"] = guild

            return channel
        end
    }
end