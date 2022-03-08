-- Slight rewrite of the dump function from luvit/pretty-print

local controls = require('./controls')

local match, find = string.match, string.find
local gsub, rep = string.gsub, string.rep
local byte = string.byte
local concat, insert = table.concat, table.insert
local type = type

local dump
local seen, output, stack = {}, {}, {}
local offset = 0

local function escape(input)
    return controls[byte(input, 1)]
end

local function recalculateOffset(index)
    for i = index + 1, #output do
        local value = output[i]
        local result = match(value, '\n([^\n]*)$')
        offset = result and #result or offset + #value
    end
end

local function write(input)
    local length = #input
    local i = 1
    local entry = stack[i]
    while offset + length > 80 and entry do
        if not entry.opened then
            local index = entry.index
            entry.opened = true
            insert(output, index + 1, '\n'..rep(' ', i))
            recalculateOffset(index)
            for x = i + 1, #stack do
                stack[x].index = stack[x].index + 1
            end
        end
        i = i + 1
        entry = stack[i]
    end
    output[#output + 1] = input
    offset = offset + length
end

local process
function process(input, esc, recursive)
    local t = type(input)
    if t == 'string' then
        if find(input, "'") and not find(input, '"') then
            write('"')
            write(esc and gsub(input, '[%c\\\128-\255]', escape) or input)
            write('"')
        else
            write("'")
            write(esc and gsub(input, '[%c\\\128-\255]', escape) or input)
            write("'")
        end
        return
    end
    if t == 'table' and not seen[input] then
        if not recursive then
            seen[input] = true
        end
        write('{ ')
        local i, nextIndex = 1, 1
        for k, v in pairs(input) do
            stack[#stack + 1] = {index = #output, opened = false}
            if k == nextIndex then
                nextIndex = k + 1
                process(v, esc, recursive)
            else
                if type(k) == 'string' and find(k, '^[%a_][%a%d_]*$') then
                    write(k)
                    write(' = ')
                else
                    write('[')
                    process(k, esc, recursive)
                    write(']')
                    write(' = ')
                end
                if type(v) == 'table' then
                    process(v, esc, recursive)
                else
                    stack[#stack + 1] = {index = #output, opened = false}
                    process(v, esc, recursive)
                    stack[#stack] = nil
                end
            end
            write(', ')
            i = i + 1
            stack[#stack] = nil
        end
        output[#output] = ' '
        write('}')
    else
        write(tostring(input))
    end
end

function dump(input, esc, recursive)
    process(input, esc, recursive)
    local result = concat(output)
    seen, output, stack = {}, {}, {}
    offset = 0
    return result
end

return dump