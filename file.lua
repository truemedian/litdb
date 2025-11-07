--[[lit-meta
    name = "code-nuage/direct-server"
    version = "0.0.2"
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
            local message, index = decoder(buffer, 1)

            while message do
                buffer = buffer:sub(index or (#buffer + 1))

                if message.method then
                    local headers = message.headers or {}
                    local body = ""

                    local content_length = tonumber(headers["content-length"])
                    if content_length then
                        if #buffer < content_length then
                            return
                        end
                        body = buffer:sub(1, content_length)
                        buffer = buffer:sub(content_length + 1)
                    end

                    local req = {
                        method = message.method,
                        path = message.path,
                        headers = headers,
                        body = body
                    }

                    local res = handler(req)
                    local code = res.code or 500
                    local reason = reasons[code] or "Unknown Reason"
                    local res_headers = res.headers or {}
                    local res_body = res.body or ""

                    res_headers["Content-Length"] = tostring(#res_body)
                    local keep_alive = message.keepAlive
                    res_headers["Connection"] = keep_alive and "keep-alive" or "close"

                    local head_chunk = encoder({
                        code = code,
                        reason = reason,
                        headers = res_headers
                    })

                    socket:write(head_chunk)
                    socket:write(res_body, function()
                        if not keep_alive then
                            socket:shutdown()
                        else
                            decoder = codec.decoder()
                        end
                    end)
                end

                message, index = decoder(buffer, 1)
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
