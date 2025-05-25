--[[lit-meta
    name = "Richy-Z/string-extensions"
    version = "0.1.4"
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

local insert = table.insert
local concat = table.concat

local random = math.random

-- yes, I know that 'injecting' my own custom functions into default libraries isn't entirely ideal
-- but its part of actually making the string library more useful
-- also for that built-in feel

return function()
    function string.startswith(str, prefix)
        return str:sub(1, #prefix) == prefix
    end

    function string.endswith(str, suffix)
        return suffix == "" or str:sub(- #suffix) == suffix
    end

    function string.trim(str)
        return str:match("^%s*(.-)%s*$")
    end

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

    function string.deregexify(str)
        local special_chars = { "%", ".", "-", "+", "*", "?", "[", "]", "^", "$", "(", ")" }
        for _, char in ipairs(special_chars) do
            str = str:gsub("%" .. char, "%%" .. char)
        end
        return str
    end

    function string.random(length, customCharset)
        if not customCharset or type(customCharset) ~= "string" then
            customCharset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        end

        local charsetLen = #customCharset

        local r = ""

        for _ = 1, length do
            local index = random(1, charsetLen)
            r = r .. customCharset:sub(index, index)
        end

        return r
    end
end
