local ws = require("coro-websocket")
local emitter = require("../utils/emitter")
local enum = require("../utils/enum")
local http = require("coro-http")
local logs = require("../utils/logs")
local json = require("json")
local timer = require("timer")

local api = "https://discord.com/api/v10/"
local ev = emitter:get("Client")
local mol = {}

local function channelObject(token, id)
    local i, gbory
    local _, body
    local success, result = pcall(function()
        _, body = http.request("GET", api.."channels/"..id, {{"Authorization", "Bot "..token}, {"Content-Type", "application/json"}})
    end)

    local channel = json.parse(body)
    local channelType = channel.type

    local scs, err = pcall(function()
        i, gbory = http.request("GET", api.."guilds/"..channel.guild_id, {{"Authorization", "Bot "..token}, {"Content-Type", "application/json"}})
    end)
    local guild = json.parse(gbory)

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

local function msgObject(obj, token)
    local payload = obj
    local author = payload.author
    local UserType = nil

    if author.system then
        UserType = enum.MemberType.System
    elseif author.bot then
        UserType = enum.MemberType.Bot
    else
        UserType = enum.MemberType.Member
    end

    local banner = nil

    if payload.author.banner then
        banner = "https://cdn.discordapp.com/banners/"..author.id.."/"..author.banner
    end

    local msg = payload
    msg["Reply"] = function(self, content)
        coroutine.wrap(function()
            local send = false

            if send == false then
                send = true
                local res, body = http.request("POST", api.."channels/"..msg.channel.id.."/messages", {{"Authorization", "Bot "..token}, {"Content-Type", "application/json"}}, json.stringify({
                    content = content,
                    message_reference = {
                        message_id = payload.id,
                        channel_id = payload.channel_id,
                        guild_id = payload.guild_id
                    }
                }))

                if res.code ~= 200 then
                    print(string.format(logs.REPLY_BAD_REQUEST, res.code))
                end
            end
        end)()
    end
    msg["Destroy"] = function(self)
        if not self then
            return
        end
        local send = false

        if send == false then
            send = true
            http.request("DELETE", api.."channels/"..msg.channel.id.."/messages/"..msg.id, {{"Authorization", "Bot "..token}})
        end
    end
    if msg.avatar then
        msg["avatar"] = "https://cdn.discordapp.com/avatars/"..author.id.."/"..author.avatar..".png"
    end
    msg["channel"] = channelObject(token, payload.channel_id)
    msg["channel_id"] = nil
    msg["banner"] = banner
    msg["system"] = nil
    msg["bot"] = nil
    msg["MemberType"] = UserType

    return msg
end

function mol.run(self, token, sts)
    coroutine.wrap(function()
        local function start()
            local session_id
            local seq
            local res, read, write = nil, nil, nil
            local success, result = pcall(function()
                res, read, write = ws.connect({
                    host = "gateway.discord.gg",
                    path = "/?v=9&encoding=json",
                    port = 443,
                    tls = true
                })
            end)

            if not success then
                print(result)
                return
            end

            local indent_payload = {
                op = 2,
                d = {   
                    token = token,
                    intents = 513,
                    properties = {
                        os = "linux",
                        browser = "discordis",
                        device = "discordis"
                    },
                    presence = {
                        activities = {},
                        status = sts,
                        since = 91879201,
                        afk = false
                    }
                }
            }

            for i in read do
                local payload = json.parse(i.payload)

                if payload then
                    local d = payload.d
                    local op = payload.op

                    if op == 10 then
                        local heartbeat_interval = d.heartbeat_interval

                        coroutine.wrap(function()
                            timer.setInterval(heartbeat_interval, function()
                                coroutine.wrap(function()
                                    write({
                                        opcode = 1,
                                        payload = json.stringify({
                                            op = 1,
                                            d = nil
                                        })
                                    })
                                end)()
                            end)
                        end)()

                        coroutine.wrap(function()
                            local response, body = write({
                                opcode = 2,
                                payload = json.stringify(indent_payload)
                            })
                        end)()
                    elseif op == 0 then
                        seq = payload.s
                    end

                    if payload.t then
                        if payload.t == "READY" then
                            session_id = payload.d.session_id
                            seq = payload.d.seq
                            ev.emit(enum.EventType.Ready)
                            print(string.format(logs.STARTED, payload.d.user.username))
                        elseif payload.t == "MESSAGE_CREATE" then
                            local msg = msgObject(payload.d, token)

                            ev.emit(enum.EventType.MessageCreate, msg)
                        elseif payload.t == "RESUMED" then
                            print("Recebemo resumed")
                            local resumedEvent = {
                                op = 6,
                                d = {
                                    token = token,
                                    session_id = session_id,
                                    seq = seq
                                }
                            }

                            write({
                                opcode = 6,
                                payload = json.stringify(resumedEvent)
                            })
                        end
                    end
                end
            end
        end
        start()
    end)()
end

return mol
