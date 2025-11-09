--[[lit-meta
    name = "code-nuage/direct-verbosity"
    version = "0.0.3"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-verbosity.lua"
    description = "The verbosity plugin of the direct web microframework."
    tags = { "direct", "plugin" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+                  +--
--  direct-verbosity  --
--  @code-nuage       --
--+                  +--

local M = {}
M._NAME = "direct-verbosity"

local colors = {
    ["RESET"] = "\27[0m",
    ["BOLD"] = "\27[1m",
    ["DIM"] = "\27[2m",
    ["ITALIC"] = "\27[3m",
    ["UNDERLINE"] = "\27[4m",

    ["RED"] = "\27[31m",
    ["GREEN"] = "\27[32m",
    ["YELLOW"] = "\27[33m",
    ["BLUE"] = "\27[34m",
    ["MAGENTA"] = "\27[35m",
    ["CYAN"] = "\27[36m",
    ["GRAY"] = "\27[90m"
}

local method_colors = {
    ["GET"] = colors["GREEN"],
    ["POST"] = colors["YELLOW"],
    ["PUT"] = colors["BLUE"],
    ["PATCH"] = colors["BLUE"],
    ["DELETE"] = colors["RED"],
    ["OPTIONS"] = colors["MAGENTA"],
    ["HEAD"] = colors["GREEN"]
}

local code_colors = {
    [1] = colors["BLUE"],
    [2] = colors["GREEN"],
    [3] = colors["MAGENTA"],
    [4] = colors["RED"],
    [5] = colors["RED"]
}

local function get_code_color(code)
    return code_colors[math.floor(code / 100)] or colors["GRAY"]
end

function M.on_load(app)
    local plugins = app:get_plugins()

    print(colors["BOLD"] .. colors["BLUE"] .. "--+          +--\n")

    for _, p in ipairs(plugins) do
        if p._NAME then
            print(string.format(
                colors["RESET"] .. "Plugin " .. "%s" .. colors["RESET"] .. " loaded\n",
                p._NAME and (colors["BOLD"] .. colors["GREEN"] .. p._NAME) or "without name"))
        end
    end

    print(colors["BOLD"] .. colors["BLUE"] .. "--+          +--\n")
end

function M.on_start(host, port)
    print(string.format(
        colors["BOLD"] .. colors["BLUE"] .. "--+          +--\n" ..
        colors["RESET"] .. "Started @ " .. colors["BOLD"] .. colors["GREEN"] .. "%s:%d\n" ..
        colors["BOLD"] .. colors["BLUE"] .. "--+          +--\n",
        host,
        port))
end

function M.on_request(req, res)
    print(string.format(
        colors["RESET"] .. "Path: " .. colors["BOLD"] .. colors["BLUE"] .. "%s\n" ..
        colors["RESET"] .. "Method: " .. colors["BOLD"] .. (method_colors[req:get_method()] or colors["GRAY"]) .. "%s\n" ..
        colors["RESET"] .. "Code: " .. colors["BOLD"] .. get_code_color(res:get_code()) .. "%d\n" ..
        colors["BOLD"] .. colors["BLUE"] .. "--+          +--",
        req:get_path(),
        req:get_method(),
        res:get_code()))
end

return M