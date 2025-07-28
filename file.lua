--[[lit-meta
    name = "Richy-Z/string-extensions"
    version = "0.2.0"
    dependencies = {}
    description = "Small extensions to Lua's default string library"
    tags = { "strings", "split", "regex", "random" }
    license = "Apache 2.0"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

-- yes, I know that 'injecting' my own custom functions into default libraries isn't entirely ideal
-- but its part of actually making the string library more useful
-- also for that built-in feel

local gmatch = string.gmatch
local find = string.find
local sub = string.sub
local rep = string.rep

local insert = table.insert
local concat = table.concat

local random = math.random

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

-- Returns the [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) between two strings - the minimum number of edits (insertions, deletions, or subtitutions) required to transform the `first` string into the `second` string.
--
-- This is useful for fuzzy matching, typo tolerance, and somewhat measuring similarity between two strings.
--
-- > **NOTE!!!**
-- > Empty strings return the length of the other string as distance.
--
-- ```lua
-- print(string.levenshtein("kitten", "sitting")) -- 3
-- print(string.levenshtein("cat", "cut"))        -- 1
-- print(string.levenshtein("banana", "banana"))  -- 0
-- ```
--
-- The function internally builds a distance matrix that tracks how much "effort" it takes to align each character of `first` with each character of `second`. Every mismatch adds a penalty (`+1`), unless the characters match (in which case it is `+0`). The bottom-right cell of the matrix (table) holds the final answer, which is the total number of edits needed.
---@param first string
---@param second string
---@return integer distance Levenshtein distance between `first` and `second`
function string.levenshtein(first, second)
    local len1, len2 = #first, #second
    if len1 == 0 then return len2 end
    if len2 == 0 then return len1 end

    local matrix = {}
    for i = 0, len1 do
        matrix[i] = {}
        matrix[i][0] = i
    end
    for j = 0, len2 do
        matrix[0][j] = j
    end

    for i = 1, len1 do
        for j = 1, len2 do
            local cost = (first:sub(i, i) == second:sub(j, j)) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i - 1][j] + 1,       -- deletion
                matrix[i][j - 1] + 1,       -- insertion
                matrix[i - 1][j - 1] + cost -- substitution
            )
        end
    end

    return matrix[len1][len2]
end

-- for legacy compatibility to not break old scripts which rely on running this as a function instead of plain requiring
return function() end
