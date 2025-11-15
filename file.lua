--[[lit-meta
    name = "code-nuage/direct-server"
    version = "0.1.0"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-server.lua"
    dependencies = {
        "luvit/coro-http",
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
local http = require("coro-http")
local reasons = require("direct-reasons")

local M = {}
M.__index = M

--+     Server     +--
function M.new()
    return setmetatable({}, M)
end

-- Getters
function M:get_host()
    return self.host or "0.0.0.0"
end

function M:get_port()
    return self.port or 8080
end

-- Setters
function M:set_host(host)
    assert(type(host) == "string",
        "Argument <host>: Must be a string.")
    self.host = host
    return self
end

function M:set_port(port)
    assert(type(port) == "number",
        "Argument <port>: Must be a number.")
    self.port = port
    return self
end

function M:start(handler)
    assert(type(handler) == "function", "Argument <handler>: Must be a function.")
    local host = self:get_host()
    local port = self:get_port()
    local server = http.createServer(host, port,
    function(request_headers, request_body)
        local request_payload = self:parse_request(request_headers, request_body)
        local response_payload = handler(request_payload)
        local res_headers, res_body = self:bundle_response(response_payload)
        return res_headers, res_body
    end)
    return server
end

function M:parse_request(request_headers, request_body)
    local method, path, body
    local headers = {}

    method = request_headers.method or "Unknown method"
    path = request_headers.path or "/"
    body = request_body

    for _, header in ipairs(request_headers) do
        headers[header[1]] = header[2]
    end

    return {
        method = method,
        path = path,
        body = body,
        headers = headers
    }
end

function M:bundle_response(response)
    local body
    local headers = {}

    headers = {
        code = response.code,
        reason = reasons[response.code] or "Unknown HTTP status"
    }
    for key, value in pairs(response.headers) do
        table.insert(headers, {key, value})
    end

    body = response.body
    return headers, body
end

return M
