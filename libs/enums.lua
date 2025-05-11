--[[
    enumerations system based on the enums.lua file from the Discordia project.
    original source: https://github.com/SinisterRectus/Discordia/blob/master/libs/enums.lua
    it was licensed under the MIT license.

    this version has been modified to better support Richy-Z/input.
]]
local function enum(tebel)
    local call = {}
    for i, v in pairs(tebel) do
        if call[v] then
            return error(string.format('Enumeration clash for %q and %q', i, call[v]))
        end
        call[v] = i
    end
    return setmetatable({}, {
        __index = function(_, key)
            if tebel[key] then
                return tebel[key]
            else
                return error("Invalid enumaration", key)
            end
        end,
        __newindex = function()
            return error("Enumerations cannot be overwritten.")
        end,
        __call = function(_, key)
            if call[key] then
                return call[key]
            else
                return error("Invalid enumeration", key)
            end
        end,
        -- __pairs = function()
        --     return next, tebel
        -- end
    })
end

local enums = { enum = enum }

-- these keycodes are based off of input from a 2024 M3 MacBook Air
-- if they are incorrect or some keycodes are missing, please create an issue or pull request
enums.macOS = enum {
    -- alphabet
    A = 0,
    B = 11,
    C = 8,
    D = 2,
    E = 14,
    F = 3,
    G = 5,
    H = 4,
    I = 34,
    J = 38,
    K = 40,
    L = 37,
    M = 46,
    N = 45,
    O = 31,
    P = 35,
    Q = 12,
    R = 15,
    S = 1,
    T = 17,
    U = 32,
    V = 9,
    W = 13,
    X = 7,
    Y = 16,
    Z = 6,

    -- symbols
    DOT = 47,            -- .
    COMMA = 43,          -- ,
    SEMICOLON = 41,      -- ;
    APOSTROPHE = 39,     -- '
    BACKTICK = 50,       -- `
    SLASH_FORWARD = 44,  -- /
    SLASH_BACKWARD = 42, -- \
    BRACKET_LEFT = 33,   -- [
    BRACKET_RIGHT = 30,  -- ]

    -- second row numbers and keys
    SECTION = 10, -- §
    NUM_1 = 18,
    NUM_2 = 19,
    NUM_3 = 20,
    NUM_4 = 21,
    NUM_5 = 23,
    NUM_6 = 22,
    NUM_7 = 26,
    NUM_8 = 28,
    NUM_9 = 25,
    NUM_0 = 29,
    MINUS = 27, -- -
    EQUAL = 24, -- =
    DELETE = 51,

    -- top row including function keys
    ESCAPE = 53,
    F1 = 122,
    F2 = 120,
    F3 = 99,
    F4 = 118,
    F5 = 96,
    F6 = 97,
    F7 = 98,
    F8 = 100,
    F9 = 101,
    F10 = 109,
    F11 = 103,
    F12 = 111,

    -- special control keys
    RETURN = 36,
    SPACE = 49,
    TAB = 48,

    -- arrow keys
    ARROW_UP = 126,
    ARROW_DOWN = 125,
    ARROW_LEFT = 123,
    ARROW_RIGHT = 124
}

return enums
