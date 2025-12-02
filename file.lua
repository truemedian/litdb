--[[lit-meta
    name = "code-nuage/direct-logs"
    version = "0.1.1"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-logs.lua"
    dependencies = {
        "luvit/coro-fs"
    }
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
local fs = require("coro-fs")

local M = {}
M._NAME = "direct-logs"
M.path = "logs.txt"

function M.set_path(path)
    assert(type(path) == "string",
        "Argument <path>: Must be a string.")
    M.path = path
end

local function append_log(message)
    coroutine.wrap(function()
        local ok, err = fs.appendFile(M.path, message)
    end)()
end



function M.on_start(host, port)
    local log = string.format(
        "Server started @ %s:%s Date: %s\n",
        host,
        tostring(port),
        os.date()
    )
    append_log(log)
end

function M.on_request(req, res)
    if res:get_signifiance() == 1 then
        local log = string.format(
            "Date: %s Path: %s Client: %s\n",
            os.date(),
            req:get_path(),
            req:get_headers()["user-agent"] or "No agent"
        )
        append_log(log)
    end
end

return M