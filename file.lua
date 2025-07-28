--[[lit-meta
    name = "Richy-Z/string-extensions"
    version = "0.1.6"
    dependencies = {}
    description = "Small extensions to Lua's default string library"
    tags = { "strings", "split", "regex", "random" }
    license = "Apache 2.0"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

local gmatch = string.gmatch
local find = string.find
local sub = string.sub
local rep = string.rep

local insert = table.insert
local concat = table.concat

local random = math.random

-- yes, I know that 'injecting' my own custom functions into default libraries isn't entirely ideal
-- but its part of actually making the string library more useful
-- also for that built-in feel








-- Returns `true` if `str` starts with `prefix`.
--
-- ```lua
-- print(string.startswith("hello world", "hel")) -- true
-- ```
---@param str string
---@param prefix string
---@return boolean
function string.startswith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

-- Returns `true` if `str` ends with `suffix`.
--
-- ```lua
-- print(string.endswith("hello.lua", ".lua")) -- true
-- ```
---@param str string
---@param suffix string
---@return boolean
function string.endswith(str, suffix)
    return suffix == "" or str:sub(- #suffix) == suffix
end

-- Strips leading and trailing whitespace from a string.
--
-- ```lua
-- print(string.trim("   padded string   ")) -- "padded string"
-- ```
---@param str string
---@return string?
function string.trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- Pads the string on the left with zeroes (`0`) until it reaches the specified width.
--
-- If the string is already at least `width` characters long, it is returned unchanged.
--
-- ```lua
-- print(string.zfill("42", 5)) -- "00042"
-- print(string.zfill("hello", 3)) -- "hello" -- not padded because it is already >= 3 chars
-- ```
---@param str string
---@param width number
---@return string
function string.zfill(str, width)
    str = tostring(str)
    return rep("0", width - #str) .. str
end

-- Splits a string by a pattern-based separator (defaults to `%s`, i.e. any whitespace).
--
-- > WARNING!!!!
-- >
-- > If the seeparator contains multiple characters, e.g. `.,`, then each character is treated as a **completely separate** delimiter. This is because the separator is treated as a Lua pattern.
-- >
-- > Please also check [`string.splitphrase`](#stringsplitphrasestr-separator) to ensure you are using the correct split for your use case. I made a huge mistake with `string.split` once, which caused me to make `string.splitphrase`.
--
-- ```lua
-- p(string.split("Hi.Bob,And.3.,44", ".,"))
-- -- { "Hi", "Bob", "And", "3", "44" }
-- -- . and , were treated as two separate delimiters
-- ```
---@param input string
---@param separator string
---@return string[]
function string.split(input, separator)
    if separator == nil then
        separator = "%s"
    end

    local out = {}
    for str in gmatch(input, "([^" .. separator .. "]+)") do
        insert(out, str)
    end

    return out
end

-- Splits a string by a literal separator (defaults to whitespace). Unlike `string.split`, the full string you provide is treated as the exact separator - not a pattern and not a set of characters.
--
-- ```lua
-- p(string.splitphrase("Hi.Bob,And.3.,44", ".,"))
-- -- { "Hi.Bob,And.3", "44" }
-- -- ., was treated as a literal separator
-- -- unlike string.split(),  The string was now only separated at the end,
-- -- where ., were present together in the exact order.
-- ```
---@param input string
---@param separator string
---@return string[]
function string.splitphrase(input, separator)
    if separator == nil then
        separator = "%s" -- default separator is whitespace
    end

    local out = {}
    local start = 1
    local sep_start, sep_end = find(input, separator, start, true)

    while sep_start do
        insert(out, sub(input, start, sep_start - 1))
        start = sep_end + 1
        sep_start, sep_end = find(input, separator, start, true)
    end

    insert(out, sub(input, start))
    return out
end

-- Wraps long strings at a given character limit (default: `80`) whilst also ensuring that words aren't broken across lines.
--
-- ```lua
-- print(string.wrap("This sentence is being wrapped after 20 characters", 20))
-- --[[
-- This sentence is
-- being wrapped after
-- 20 characters
-- ]]
-- ```
---@param str string
---@param limit? number
---@return string
function string.wrap(str, limit)
    limit = limit or 80
    local out = {}
    local line = ""

    for word in str:gmatch("%S+") do
        if #line + #word + 1 > limit then
            insert(out, line)
            line = word
        else
            if #line > 0 then
                line = line .. " " .. word
            else
                line = word
            end
        end
    end

    if #line > 0 then
        insert(out, line)
    end

    return concat(out, "\n")
end

-- Escapes all Lua pattern characters in a string so it can be safely used in `string.match`, `string.gsub`, etc. without being interpreted as actual pattern characters.
--
-- ```lua
-- local escaped = string.deregexify("1+1=2?")
-- print(escaped) -- "1%+1=2%?"
-- ```
---@param str string
---@return string
function string.deregexify(str)
    local special_chars = { "%", ".", "-", "+", "*", "?", "[", "]", "^", "$", "(", ")" }
    for _, char in ipairs(special_chars) do
        str = str:gsub("%" .. char, "%%" .. char)
    end
    return str
end

-- Generates a random string that is `length` characters long, using the given charset (or alphanumerics by default, if `charset` is omitted.)
--
-- ```lua
-- print(string.random(10)) -- e.g. "aZ7qT19BcP"
--
-- print(string.random(5, "abc")) -- e.g. "abacb"
-- ```
---@param length number
---@param charset? string
---@return string
function string.random(length, charset)
    if not (charset and type(charset) == "string") then
        charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    end

    local charsetLen = #charset

    local r = ""

    for _ = 1, length do
        local index = random(1, charsetLen)
        r = r .. charset:sub(index, index)
    end

    return r
end

-- for legacy compatibility to not break old scripts which rely on running this as a function instead of plain requiring
return function() end
