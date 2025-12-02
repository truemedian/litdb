--[[lit-meta
    name = "code-nuage/direct-verbosity"
    version = "0.0.7"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-verbosity.lua"
    dependencies = {
        "code-nuage/direct-colors"
    }
    description = "The verbosity plugin of the direct web microframework."
    tags = { "direct", "plugin" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+                  +--
--  direct-verbosity  --
--  @code-nuage       --
--+                  +--

--+ Dependencies +--
local colors = require("direct-colors")

local M = {}
M._NAME = "direct-verbosity"

local color = {
    {color = "BLUE", variant = "BOLD"},
    {color = "GREEN", variant = "BOLD"}
}

local method_colors = {
    ["GET"] = "GREEN",
    ["POST"] = "YELLOW",
    ["PUT"] = "BLUE",
    ["PATCH"] = "BLUE",
    ["DELETE"] = "RED",
    ["OPTIONS"] = "PURPLE",
    ["HEAD"] = "GREEN"
}

local code_colors = {
    [1] = "BLUE",
    [2] = "GREEN",
    [3] = "PURPLE",
    [4] = "RED",
    [5] = "RED"
}

local function get_code_color(code)
    return code_colors[math.floor(code / 100)] or "BLACK"
end

function M.on_load(app)
    local plugins = app:get_plugins()

    print(colors.colorize("--+          +--", color[1]))

    for _, p in ipairs(plugins) do
        if p._NAME then
            print(string.format("Plugin %s loaded",
                p._NAME and (colors.colorize(p._NAME, color[2])) or
                colors.colorize("without name", {colors = "RED", variant = "BOLD", mode = "HIGH_INTENSITY"})))
        end
    end

    print(colors.colorize("--+          +--", color[1]))
end

function M.on_start(host, port)
    print(string.format(
        colors.colorize("--+          +--", color[1]) .. "\n" ..
        "Started @ " .. colors.colorize("%s:%d", color[2]) .. "\n" ..
        colors.colorize("--+          +--", color[1]) .. "\n\n" ..
        colors.colorize("--+          +--", color[1]),
        host,
        port))
end

function M.on_request(req, res)
    if req:get_signifiance() == 1 then
        print(string.format(
            "Path: " .. colors.colorize("%s", color[1]) .. "\n" ..
            "Client: " .. colors.colorize("%s", color[1]) .. "\n" ..
            "Method: " .. colors.colorize("%s", {color = method_colors[req:get_method()] or "BLACK", variant = "BOLD", mode = "HIGH_INTENSITY"}) .. "\n" ..
            "Code: " .. colors.colorize(" %d ", {color = get_code_color(res:get_code()), variant = "BOLD", mode = "BACKGROUND_HIGH_INTENSITY"}) .. "\n" ..
            colors.colorize("--+          +--", color[1]),
            req:get_path(),
            req:get_header("User-Agent"),
            req:get_method(),
            res:get_code()))
    end
end

return M