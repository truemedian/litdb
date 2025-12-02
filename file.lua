--[[lit-meta
    name = "code-nuage/direct-publicize"
    version = "0.1.2"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-publicize.lua"
    dependencies = {
        "luvit/coro-fs",
        "luvit/pathjoin",
        "code-nuage/direct-mime",
        "code-nuage/direct-colors"
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
local fs = require("coro-fs")
local path_join = require("pathjoin").pathJoin
local mime = require("direct-mime")
local colors = require("direct-colors")

local M = {}
M._NAME = "direct-publicize"
M.path = path_join(require("uv").cwd(), "Public")

function M.on_load(app, directory, path_prefix)
    directory = directory or M.path
    path_prefix = path_prefix or ""

    return coroutine.wrap(function()
        for entry, scan_err in fs.scandir(directory) do
            if not entry then
                error(string.format("Can't scan: %s", scan_err))
            end

            local full_path = path_join(directory, entry.name)

            if entry.type == "file" then
                local route = path_prefix .. "/" .. entry.name
                app:add_route(route, "GET", function(req, res)
                    local data, read_err = fs.readFile(full_path)

                    if not data then
                        print(string.format(colors.colorize("Cannot read file %s: %s", {color = "RED", variant = "BOLD"})),
                            entry.name, read_err)
                        return
                    end

                    res:set_code(200)
                    res:set_header("Content-Type", mime.guess(entry.name))
                    res:set_body(data or "")
                end, 2)
            elseif entry.type == "directory" then
                M.on_load(app, full_path, path_prefix .. "/" .. entry.name)
            end
        end
    end)()
end

return M

