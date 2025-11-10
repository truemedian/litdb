--[[lit-meta
    name = "code-nuage/direct-publicize"
    version = "0.0.2"
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
local path_join = require("pathjoin").pathJoin

local mime = require("direct-mime")

local M = {}
M._NAME = "direct-publicize"
M.path = path_join(require("uv").cwd(), "Public")

function M.on_load(app, directory, path_prefix)
    path_prefix = path_prefix or ""
    directory = directory or M.path

    for entry in fs.scandirSync(directory) do
        local full_path = path_join(directory, entry)
        local stat = fs.statSync(full_path)
        if stat then
            if stat.type == "file" then
                local route = path_prefix .. "/" .. entry
                app:add_route(route, "GET", function(req, res)
                    local data = fs.readFileSync(full_path)
                    res:set_code(200)
                    res:set_header("Content-Type", mime.guess(entry))
                    res:set_body(data or "")
                end)
            elseif stat.type == "directory" then
                M.on_load(app, full_path, path_prefix .. "/" .. entry)
            end
        end
    end
end

return M