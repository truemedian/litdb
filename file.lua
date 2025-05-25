--[[lit-meta
    name = "Richy-Z/string-extensions"
    version = "0.1.3"
    dependencies = {}
    description = "Small extensions to Lua's default string library"
    tags = { "strings", "split", "regex", "random" }
    license = "Apache 2.0"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

return function()
    function string.split(input, separator)
        if separator == nil then
            separator = "%s"
        end

        local out = {}
        for str in string.gmatch(input, "([^" .. separator .. "]+)") do
            table.insert(out, str)
        end

        return out
    end

    function string.splitphrase(input, separator)
        if separator == nil then
            separator = "%s" -- default separator is whitespace
        end

        local out = {}
        local start = 1
        local sep_start, sep_end = string.find(input, separator, start, true)

        while sep_start do
            table.insert(out, string.sub(input, start, sep_start - 1))
            start = sep_end + 1
            sep_start, sep_end = string.find(input, separator, start, true)
        end

        table.insert(out, string.sub(input, start))
        return out
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

        local random = ""

        for _ = 1, length do
            local index = math.random(1, charsetLen)
            random = random .. customCharset:sub(index, index)
        end

        return random
    end
end
