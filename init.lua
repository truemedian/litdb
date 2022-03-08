local dump = require('dump')
local colorize = require('colorize')
local formatter = require('formatter')

local find, sub = string.find, string.sub
local select, tostring = select, tostring
local concat = table.concat
local realPrint = print

local function print(...)
    local n = select('#', ...)
    local args = {...}
    for i = 1, n do
        local arg = tostring(args[i])
        local start, finish, colors, input = find(arg, '(%b[])(%b())')
        if start then
            local colored = colorize(sub(colors, 2, -2), sub(input, 2, -2))
            args[i] = sub(arg, 1, start - 1)..colored..sub(arg, finish + 1, #arg)
        else
            args[i] = arg
        end
    end
    return realPrint(concat(args, '\t'))
end

return {
    colorize = colorize,
    print = print,
    dump = dump,
    formatter = formatter
}