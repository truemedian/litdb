--[[lit-meta
    name = "code-nuage/direct-router"
    version = "0.1.1"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-router.lua"
    dependencies = {
        "code-nuage/direct-server"
    }
    description = "The router of the direct web microframework."
    tags = { "direct" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+               +--
--  direct-router  --
--  @code-nuage    --
--+               +--

--+ Dependencies +--
local server = require("direct-server")

local M = {}
M.__index = M

--+   Router   +--
function M.new()
    local i = setmetatable({}, M)

    i.routes = {}
    i.plugins = {}

    return i
end

function M:start()
    local host, port = self:get_host(), self:get_port()
    self:hook("on_start", host, port)
    server.start_server(host, port, function(request_payload)
        local req, res = M.request.new(request_payload), M.response.new()
        local method, path = req:get_method(), req:get_path()
        self:get_route(method, path)(req, res)
        self:hook("on_request", req, res)
        return res:build()
    end)
end

-- Getters
function M:get_host()
    return self.host or "0.0.0.0"
end

function M:get_port()
    return self.port or 8080
end

function M:get_route(method, path)
    local route = self.routes[path]
    if route and route.method == method then
        return route.callback
    end
    return self:get_route_not_found()
end

function M:get_route_not_found()
    return self.route_not_found or function(req, res)
        res
        :set_code(404)
        :set_body("Resource not found at " .. req:get_path())
    end
end

function M:get_plugins()
    return self.plugins
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

function M:add_route(path, method, callback)
    assert(type(path) == "string",
        "Argument <path>: Must be a string.")
    assert(type(method) == "string",
        "Argument <method>: Must be a string.")
    assert(type(callback) == "function",
        "Argument <callback>: Must be a function.")
    self.routes[path] = {
        method = method,
        callback = callback
    }
    return self
end

function M:set_route_not_found(callback)
    assert(type(callback) == "function",
        "Argument <callback>: Must be a function.")
    self.route_not_found = callback
    return self
end

function M:add_plugin(plugin)
    assert(type(plugin) == "table",
        "Argument <plugin>: Must be a table.")
    table.insert(self.plugins, plugin)
    if type(plugin["on_load"]) == "function" then
        plugin["on_load"](self)
    end
    return self
end

-- Plugins
function M:hook(name, ...)
    local plugins = self:get_plugins()

    for _, p in ipairs(plugins) do
        if type(p[name]) == "function" then
            p[name](...)
        end
    end
end

--+ Request +--
M.request = {}
M.request.__index = M.request

function M.request.new(payload)
    local i = setmetatable({}, M.request)

    i.headers = {}
    i:build(payload)

    return i
end

-- Getters
function M.request:get_method()
    return self.method or "?"
end

function M.request:get_path()
    return self.path or "/"
end

function M.request:get_body()
    return self.body
end

function M.request:get_headers()
    return self.headers
end

-- Setters
function M.request:set_method(method)
    assert(type(method) == "string",
        "Argument <method>: Must be a string.")
    self.method = method
    return self
end

function M.request:set_path(path)
    assert(type(path) == "string",
        "Argument <path>: Must be a string.")
    self.path = path
    return self
end

function M.request:set_header(key, value)
    assert(type(key) == "string" and type(value) == "string",
        "Argument <key> & <value>: Must be strings.")
    self.headers[key] = value
    return self
end

function M.request:set_body(body)
    assert(type(body) == "string",
        "Argument <body>: Must be a string.")
    self.body = body
    return self
end

-- Build
function M.request:build(payload)
    self
    :set_method(payload["method"])
    :set_path(payload["path"])
    :set_body(payload["body"])

    for key, value in pairs(payload["headers"]) do
        self:set_header(key, value)
    end
end

--+ Response +--
M.response = {}
M.response.__index = M.response

function M.response.new()
    local i = setmetatable({}, M.response)

    i.headers = {}

    return i
end

-- Getters
function M.response:get_code()
    return self.code or 500
end

function M.response:get_headers()
    return self.headers or {}
end

function M.response:get_body()
    return self.body or ""
end

-- Setters
function M.response:set_code(code)
    assert(type(code) == "number",
        "Argument <code>: Must be a number.")
    self.code = code
    return self
end

function M.response:set_header(key, value)
    assert(type(key) == "string" and type(value) == "string",
        "Argument <key> & <value>: Must be strings.")
    self.headers[key] = value
    return self
end

function M.response:set_body(body)
    assert(type(body) == "string",
        "Argument <body>: Must be a string.")
    self.body = body
    return self
end

-- Build
function M.response:build()
    return {
        code = self:get_code(),
        headers = self:get_headers(),
        body = self:get_body()
    }
end

return M
