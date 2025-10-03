
-- direct/router
-- @code-nuage

local pathJoin = require("pathjoin").pathJoin

local http = require("coro-http")
local fs = require("coro-fs")

local mime = require("./mime.lua")
local reasons = require("./reasons.lua")

--+    UTILS     +--
local colors = {
    reset =   "\27[0m",
    black =   "\27[31;1m",
    red =     "\27[31;1m",
    green =   "\27[32;1m",
    yellow =  "\27[33;1m",
    blue =    "\27[34;1m",
    magenta = "\27[35;1m",
    cyan =    "\27[36;1m",
    gray =    "\27[37;1m"
}

local function get_color_from_status_code(status)
    local hundreds_colors = {
        [1] = colors.blue,
        [2] = colors.green,
        [3] = colors.yellow,
        [4] = colors.red,
        [5] = colors.red,
    }

    local hundreds = math.floor(status / 100)

    return hundreds_colors[hundreds] or colors.red
end

local function get_color_from_method(method)
    local method_colors = {
        ["GET"] = colors.green,
        ["POST"] = colors.yellow,
        ["PUT"] = colors.blue,
        ["PATCH"] = colors.cyan,
        ["DELETE"] = colors.red,
        ["HEAD"] = colors.green,
        ["OPTIONS"] = colors.magenta,
    }

    return method_colors[method] or colors.gray
end

local function guess_mime(path)
    local ext = path:match("%.([%w]+)$")
    if ext and mime[ext] then
        return mime[ext]
    end
    return "application/octet-stream"
end

--+     ROUTER     +--
local router = {}
router.__index = router

function router.new()
    local i = setmetatable({}, router)

    i.routes = {}
    i.name = "router"
    i.host = nil
    i.port = nil
    i.verbosity = false

    return i
end

function router:set_name(name)
    assert(type(name) == "string", "Argument <name> must be a string.")
    self.name = name
    return self
end

function router:set_verbosity(verbosity)
    assert(type(verbosity) == "boolean", "Argument <verbosity> must be a boolean.")
    self.verbosity = verbosity
    return self
end

function router:bind(host, port)
    assert(type(host) == "string", "Argument <host> must be a string.")
    assert(type(port) == "number", "Argument <port> must be a number.")
    self.host, self.port = host, port
    return self
end

function router:set_route(route, method, controller)
    local keys = {}

    local pattern = route:gsub("(:%w+)", function(key)
        table.insert(keys, key:sub(2))
        return "([^/:]+)"
    end)

    pattern = "^" .. pattern .. "$"

    table.insert(self.routes, {
        ["Pattern"] = pattern,
        ["Method"] = method,
        ["Keys"] = keys,
        ["Controller"] = controller
    })

    return self
end

function router:publicize(dirpath, route_base)
    assert(type(dirpath) == "string", "Argument <dirpath> must be a string.")
    route_base = route_base or ""

    for entry in fs.scandir(dirpath) do
        local fullpath = pathJoin(dirpath, entry.name)

        if entry.type == "file" then
            local route_path = route_base .. "/" .. entry.name

            self:set_route(route_path, "GET", function(_, res)
                local content, err = fs.readFile(fullpath)

                if not content then
                    res:set_status(500)
                    res:set_header("Content-Type", "text/plain")
                    res:set_body("Internal server error: " .. err)
                    return
                end

                res:set_status(200)
                res:set_header("Content-Type", guess_mime(fullpath))
                res:set_body(content)
            end)

        elseif entry.type == "directory" then
            self:publicize(fullpath, route_base .. "/" .. entry.name)
        end
    end

    return self
end


function router:set_not_found(controller)
    self.not_found_controller = controller
    return self
end

function router:not_found(req, res)
    if type(self.not_found_controller) == "function" then
        self.not_found_controller(req, res)
    else
        res["Status-Code"], res["Headers"]["Content-Type"], res["Body"] = 404, "text/plain", "No ressource found at " .. req["Path"]
    end
end

function router:handle_request(req, res)
    table.sort(self.routes, function(a, b)
        return #a["Keys"] < #b["Keys"]
    end)

    for _, route in ipairs(self.routes) do
        if route["Method"] == req["Method"] then
            local match = req:get_path():match(route["Pattern"])
            if match then
                local captures = {req:get_path():match(route["Pattern"])}
                for i, key in ipairs(route["Keys"]) do
                    req:set_param(key, captures[i])
                end
                return route["Controller"](req, res)
            end
        end
    end

    self:not_found(req, res)
end

function router:display_request(req, res)
    print("--+     " .. colors.blue .. req["Path"] .. colors.reset .. "     +--" .. colors.reset ..
    "\nClient: " .. colors.blue .. (req["Headers"]["User-Agent"] or "?") .. colors.reset ..
    "\nMethod: " .. get_color_from_method(req["Method"]) .. req["Method"] .. colors.reset ..
    "\nPath: " .. colors.blue .. req["Path"] .. colors.reset ..
    "\nStatus-Code: " .. get_color_from_status_code(res["Status-Code"]) .. res["Status-Code"] .. colors.reset ..
    "\n--+" .. string.rep(" ", #req["Path"] + 10) .. "+--\n")
end

--+ REQUEST +--
local request = {}
request.__index = request

function request.new(head, body)
    local i = setmetatable({}, request)

    i["HTTP-Version"] = head.version

    i["Path"] = head.path:gsub("%?.*$", "")
    i["Path"] = i["Path"] :gsub("/+$", "")
    if i["Path"] == "" then i["Path"]  = "/" end

    i["Method"] = head.method
    i["Headers"] = {}
    i["Body"] = nil
    i["Params"] = {}

    for _, header in ipairs(head) do
        local name, value = header[1], header[2]
        i["Headers"][name] = value
    end

    if body and body ~= "" then
        i["Body"] = body
    end

    return i
end

-- SETTERS
function request:set_param(name, value)
    self["Params"][name] = value
end

-- GETTERS
function request:get_http_ver()
    return self["HTTP-Version"]
end

function request:get_path()
    return self["Path"]
end

function request:get_method()
    return self["Method"]
end

function request:get_header(header)
    return self["Headers"][header]
end

function request:get_headers()
    return self["Headers"]
end

function request:get_body_raw()
    return true, self["Body"]
end

function request:get_params()
    return self["Params"]
end

function request:get_param(param)
    return self["Params"][param]
end

--+ RESPONSE +--
local response = {}
response.__index = response

function response.new()
    local i = setmetatable({}, response)

    i["HTTP-Version"] = nil
    i["Status-Code"] = nil
    i["Headers"] = {}
    i["Body"] = nil

    return i
end

-- SETTERS
function response:set_http_ver(http_ver)
    self["HTTP-Version"] = http_ver
    return self
end

function response:set_status(status_code)
    self["Status-Code"] = status_code
    return self
end

function response:set_header(name, value)
    self["Headers"][name] = value
    return self
end

function response:set_body(body)
    self["Body"] = body
    return self
end

-- GETTERS
function response:get_http_ver()
    return self["HTTP-Version"]
end

function response:get_status()
    return self["Status-Code"]
end

function response:get_header(name)
    return self["Headers"][name]
end

function response:get_headers()
    return self["Headers"]
end

function response:get_body()
    return self["Body"]
end

--+ START +--
function router:display_server()
    print("--+     " .. colors.blue .. self.name .. colors.reset .. "     +--" .. colors.reset ..
    "\nHost: " .. colors.blue .. self.host .. colors.reset ..
    "\nPort: " .. colors.blue .. self.port .. colors.reset ..
    "\n--+" .. string.rep(" ", #self.name + 10) .. "+--\n")
end

function router:start()
    if self.verbosity then
        self:display_server()
    end
    http.createServer(self.host, self.port, function(head, body)
        local req = request.new(head, body)

        local res = response.new()

        self:handle_request(req, res)
        self:display_request(req, res)

        local headers = {}
        for name, value in pairs(res:get_headers()) do
            table.insert(headers, {name, value})
        end

        local status = res:get_status()

        return {
            code = status or 500,
            reason = status and reasons[status] or "?",
            {"Content-Length", res:get_body() and #res:get_body() or ""},
            table.unpack(headers),
            keepAlive = true
        }, res:get_body() or ""
    end)
end

return router
