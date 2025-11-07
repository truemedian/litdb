--[[lit-meta
    name = "code-nuage/direct-logs"
    version = "0.0.2"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-logs.lua"
    description = "The logs plugin of the direct web microframework."
    tags = { "direct", "plugin" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+             +--
--  direct-logs  --
--  @code-nuage  --
--+             +--

--+ Dependencies +--
local fs = require("fs")

local M = {}
M._NAME = "direct-logs"
M.path = "logs.txt"

function M.set_path(path)
    assert(type(path) == "string",
        "Argument <path>: Must be a string.")
    M.path = path
end



function M.on_start(host, port)
    local log = string.format(
        "Server started @ %s:%s Date: %s\n",
        host,
        tostring(port),
        os.date()
    )
    fs.open(M.path, "a+", function(err, fd)
    if err then return end
        fs.write(fd, 0, log, function(err2)
            fs.close(fd, function(err3) end)
        end)
    end)
end

function M.on_request(req, _)
    local log = string.format(
        "Date: %s Path: %s Client: %s\n",
        os.date(),
        req:get_path(),
        req:get_headers()["user-agent"] or "No agent"
    )
    fs.open(M.path, "a+", function(err, fd)
    if err then return end
        fs.write(fd, 0, log, function(err2)
            fs.close(fd, function(err3) end)
        end)
    end)
end

return M