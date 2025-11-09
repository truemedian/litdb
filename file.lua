--[[lit-meta
    name = "code-nuage/direct-publicize"
    version = "0.0.1"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-publicize.lua"
    dependencies = {
        "luvit/fs",
        "luvit/pathjoin",
        "code-nuage/direct-mime"
    }
    description = "The publicize plugin of the direct web microframework."
    tags = { "direct" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+                  +--
--  direct-publicize  --
--  @code-nuage       --
--+                  +--

--+ Dependencies +--
local fs = require("fs")
local path_join = require("pathjoin").pathjoin

local mime = require("direct-mime")

local M = {}
M._NAME = "direct-publicize"
M.path = "./Public"

function M.on_load(app, directory, route_prefix)
    route_prefix = route_prefix or ""

    local entries = {}
    for entry in fs.scandir(directory) do
        table.insert(entries, entry)
    end

    for i, entry in ipairs(entries) do
        local last = (i == #entries)

        if entry.type == "file" then
            local route = route_prefix .. "/" .. entry.name
            app:set_route(route, "GET", function(req, res)
                local data = fs.readFile(path_join(directory, entry.name))
                res:set_code(200)
                res:set_header("Content-Type", mime.guess(entry.name))
                res:set_body(data or "")
            end)
        elseif entry.type == "directory" then
            M.on_load(app, path_join(directory, entry.name),
                route_prefix .. "/" .. entry.name)
        end
    end
end

return M