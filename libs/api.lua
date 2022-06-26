local websocket = require("coro-websocket")
local http = require("coro-http")
local time = require("timer")
local json = require("json")

local Message = require("../classes/message")
local Interaction = require("../classes/interaction")
local User = require("../classes/user")

local Object = require("discord.lua/classes/class")

local wrap = coroutine.wrap

local api = Object:extend()

api.api = nil

function api:new(client)
    self.client = client
    self.rest = "https://discord.com/api/v10"
    api.api = self
    return self
end

function api:login(token)

    os.execute("color 2")

    print("[DISCORD.LUA] Connecting to gateway.discord.gg")

    local res,read,write = websocket.connect{
        host = "gateway.discord.gg",
        pathname = "/?v=10&encoding=json",
        tls = true,
        port = 443,
    }

    print("[DISCORD.LUA] Connected to gateway.discord.gg")

    if not res then
        return print(read())
    end

    local hello_payload = json.decode(read().payload)

    function send(pl)
        return write{
            opcode = 1,
            payload = json.encode(pl) --opcode = old_payload.op or 2,
        }
    end

    time.setInterval(hello_payload.d.heartbeat_interval,function()
        wrap(function()
            send({
                op = 11,
            })
        end)()
    end)
    wrap(function()
        local sucess,err = send({
            op = 2,
            d = {
                token = token,
                intents = 131071,
                properties = {
                    os = "linux",
                    browser = "discord.lua",
                    device = "discord.lua"
                }
            }
        })
        if not sucess then
            print("[DISCORD.LUA] Failed identifing: " .. err)
        else
            print("[DISCORD.LUA] Identified")
        end
    end)()
    wrap(function ()
        for pl in read do
            local raw_event = pl.payload
            if raw_event then
                local event,err = json.decode(raw_event)
                if event then
                    if event.op == 2 then
                        print("[DISCORD.LUA] Identified")
                        self.client:add_user(User(event.d))
                    end
                    if event.op == 0 then
                        if event.t == "MESSAGE_CREATE" then
                            self.client:emit(event.t,Message(event.d))
                        end
                        if event.t == "INTERACTION_CREATE" then
                            self.client:emit(event.t,Interaction(event.d))
                        end
                    end
                    if event.op == 10 then
                        print("[DISCORD.LUA] Received HELLO")
                    end
                else
                    print(err)
                end
            end
        end
    end)()
    print("[DISCORD.LUA] Heartbeating")
end

function api:request(method,endpoint,payload_body)
    local res,body = http.request(method,"https://discord.com/api/v10/" .. endpoint,{{"Authorization","Bot " .. self.client.token},{"Content-Type","application/json"}},json.encode(payload_body))
    if res.code ~= 200 then
        return print(res.reason)
    end
    return json.decode(body)
end

function api.get()
    return api.api
end

return api