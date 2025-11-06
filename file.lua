--[[lit-meta
    name = "code-nuage/direct-server"
    version = "0.0.1"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-server.lua"
    dependencies = {
        "luvit/net",
        "luvit/http-codec",
        "code-nuage/direct-reasons"
    }
    description = "The server of the direct web microframework."
    tags = { "direct" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+               +--
--  direct-server  --
--  @code-nuage    --
--+               +--

-- direct-server.lua
local net = require("net")
local codec = require("http-codec")
local reasons = require("direct-reasons")

local M = {}

function M.start_server(host, port, handler)
    assert(type(handler) == "function", "Argument <handler>: Must be a function.")
    host = host or "0.0.0.0"
    port = port or 8080

    local server = net.createServer(function(socket)
        local decoder = codec.decoder()
        local encoder = codec.encoder()
        local buffer = ""

        local function process_request()
            while true do
                local message, extra = decoder(buffer)
                if not message then break end
                buffer = extra or ""

                if message.method then
                    local headers = message.headers or {}
                    local body = ""

                    if tonumber(headers["content-length"]) then
                        local length = tonumber(headers["content-length"])
                        if #buffer >= length then
                            body = buffer:sub(1, length)
                            buffer = buffer:sub(length + 1)
                        else
                            return
                        end
                    end

                    local request_payload = {
                        method = message.method,
                        path = message.path,
                        headers = headers,
                        body = body
                    }

                    local response_payload = handler(request_payload)
                    local code = response_payload.code or 500
                    local reason = reasons[code] or "Unknown reason"
                    local res_headers = response_payload.headers or {}
                    local res_body = response_payload.body or ""

                    res_headers["Content-Length"] = tostring(#res_body)

                    if message.keepAlive then
                        res_headers["Connection"] = "keep-alive"
                    else
                        res_headers["Connection"] = "close"
                    end

                    local header_chunk = encoder({
                        code = code,
                        reason = reason,
                        headers = res_headers
                    })
                    local body_chunk = encoder(res_body)

                    socket:write(header_chunk, function()
                        socket:write(body_chunk, function()
                            socket:shutdown()
                        end)
                    end)
                end
            end
        end

        socket:on("data", function(chunk)
            buffer = buffer .. chunk
            process_request()
        end)

        socket:on("error", function(err)
            print("Socket error:", err)
            socket:shutdown()
        end)
    end)

    server:listen(port, host)
    return server
end

return M
