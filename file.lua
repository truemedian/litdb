--[[lit-meta
	name = 'TohruMKDM/bytes'
	version = '1.0.1'
	homepage = 'https://github.com/TohruMKDM/bytes'
	description = 'Utility to parse a string bytes (ex: 1TB) to bytes (1099511627776) and vice-versa.'
	tags = {'byte', 'bytes', 'utility', 'parse', 'parser', 'convert', 'converter'}
	license = 'MIT'
	author = {name = 'Tohru~ (トール)', email = 'admin@ikaros.pw'}
]]


---@class formatOptions
---@field public decimalPlaces number | nil Maximum number of decimal places to include in output. Default value to `2`.
---@field public thousandsSeparator string | nil Example of values: `' '`, `','` and `'.'`... Default value to `''`.
---@field public unit string | nil The unit in which the result will be returned (B/KB/MB/GB/TB). Default value to `''` (which means auto detect).
---@field public unitSeparator string | nil Separator to use between number and unit. Default value to `''`.

local lshift = bit.lshift
local pow, abs, floor = math.pow, math.abs, math.floor
local lower, reverse = string.lower, string.reverse
local gsub, match = string.gsub, string.match

local map = {
    b = 1,
    kb = lshift(1, 10),
    mb = lshift(1, 20),
    gb = lshift(1, 30),
    tb = pow(1024, 4),
    pb = pow(1024, 5)
}
local default = {decimalPlaces = 2, fixedDecimals = false, thousandsSeparator = '', unit = '', unitSeparator = ''}

local function round(n, i)
	local m = 10 ^ (i or 0)
	return floor(n * m + 0.5) / m
end

---Default export function. Delegates to either `bytes.format` or `bytes.parse` based on the type of value.
---@overload fun(value: string | number, options?: formatOptions): string | number | nil
local bytes = {}

---Format the given value in bytes into a string. If the value is negative, it is kept as such. If it is a float, it is rounded.
---@param value number Value in bytes
---@param options? formatOptions Conversion options
---@return string | nil
function bytes.format(value, options)
    if not tonumber(value) then
        return nil
    end
    local opts = {}
    for i, v in pairs(default) do
        opts[i] = options and options[i] or v
    end
    options = opts
    local mag = abs(value)
    if options.unit == '' or not map[lower(options.unit)] then
        if mag >= map.pb then
            options.unit = 'PB'
        elseif mag >= map.tb then
            options.unit = 'TB'
        elseif mag >= map.gb then
            options.unit = 'GB'
        elseif mag >= map.mb then
            options.unit = 'MB'
        elseif mag >= map.kb then
            options.unit = 'KB'
        else
            options.unit = 'B'
        end
    end
    local result = round(value / map[lower(options.unit)], options.decimalPlaces)
    if options.thousandsSeparator ~= '' then
        local negative,  number, decimal = match(result, '(%-?)(%d+)(%.?%d*)')
        number = gsub(reverse(number), '(%d%d%d)(%d)', '%1'..options.thousandsSeparator..'%2')
        result = negative..reverse(number)..decimal
    end
    return result..options.unitSeparator..options.unit
end

--[[Parse the string value into an integer in bytes. If no unit is given, or `value` is a number, it is assumed the value is in bytes.

Supported units and abbreviations are as follows and are case-insensitive:
• `b` for bytes

• `kb` for kilobytes

• `mb` for megabytes

• `gb` for gigabytes

• `tb` for terabytes

• `pb` for petabytes

The units are in powers of two, not ten. This means 1kb = 1024b according to this parser.]]
---@param value string String to parse
---@return number | nil
function bytes.parse(value)
    if tonumber(value) then
        return value
    end
    local number, unit = match(value, '(%-?%d+)(%a%a)')
    if not number or not map[lower(unit)] then
        return nil
    end
    return floor(number * map[lower(unit)])
end

return setmetatable(bytes, {
    __call = function(_, value, options)
        if tonumber(value) then
            return bytes.format(value, options)
        elseif type(value) == 'string' then
            return bytes.parse(value)
        end
        return nil
    end
})