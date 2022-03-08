local format = string.format
local concat = table.concat
local select, tostring = select, tostring

local bold = '\027[1m%s\027[0m'
local faint = '\027[2m%s\027[0m'
local underline = '\027[4m%s\027[0m'
local blink = '\027[5m%s\027[0m'

local formatter = setmetatable({}, {
    __call = function(self, fmt, ...)
        return self[fmt](...)
    end
})

function formatter.bold(...)
    local n = select('#', ...)
    local args = {...}
    for i = 1, n do
        args[i] = tostring(args[i])
    end
    return format(bold, concat(args))
end

function formatter.faint(...)
    local n = select('#', ...)
    local args = {...}
    for i = 1, n do
        args[i] = tostring(args[i])
    end
    return format(faint, concat(args))
end

function formatter.underline(...)
    local n = select('#', ...)
    local args = {...}
    for i = 1, n do
        args[i] = tostring(args[i])
    end
    return format(underline, concat(args))
end

function formatter.blink(...)
    local n = select('#', ...)
    local args = {...}
    for i = 1, n do
        args[i] = tostring(args[i])
    end
    return format(blink, concat(args))
end

return formatter