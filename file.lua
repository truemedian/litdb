--[[lit-meta
    name = "code-nuage/direct-colors"
    version = "0.1.1"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-colors.lua"
    description = "CLI colors for the direct web microframework."
    tags = { "direct" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+               +--
--  direct-colors  --
--  @code-nuage    --
--+               +--

local M = {}

M.colors = {
    modes = {
        ["NORMAL"] =                    3,
        ["BACKGROUND"] =                4,
        ["HIGH_INTENSITY"] =            9,
        ["BACKGROUND_HIGH_INTENSITY"] = 10,
    },

    -- Text mode
    variants = {
        ["REGULAR"] =   0,
        ["BOLD"] =      1,
        ["UNDERLINE"] = 4,
    },

    -- Color variant
    colors = {
        ["BLACK"] =  0,
        ["RED"] =    1,
        ["GREEN"] =  2,
        ["YELLOW"] = 3,
        ["BLUE"] =   4,
        ["PURPLE"] = 5,
        ["CYAN"] =   6,
        ["WHITE"] =  7,
    },

    -- Utils
    ["RESET"] = "\27[0m"
}

local function resolve_color(mode, submode, default)
    return submode and M.colors[mode][submode] or M.colors[mode][default]
end

local function resolve_args(mode, color, variant)
    local new_mode, new_color, new_variant =
    resolve_color("modes", mode, "NORMAL"),
    resolve_color("colors", color, "BLACK"),
    resolve_color("variants", variant, "REGULAR")

    return new_mode, new_color, new_variant
end

local function build_color(mode, color, variant)
    mode, color, variant =
    resolve_args(mode, color, variant)

    return string.format("\27[%d;%d%dm", variant, mode, color)
end

function M.colorize(text, options)
    assert(type(text) == "string",
        "Argument <string>: Must be a string.")
    assert(type(options) == "table",
        "Argument <options>: Must be a table with optionals {mode, color, variant} as keys.")
    local new_text

    local mode, color, variant =
    options.mode or nil,
    options.color or nil,
    options.variant or nil

    new_text = string.format("%s%s%s",
        build_color(mode, color, variant),
        text, M.colors["RESET"])

    return new_text
end

return M
