-- converted from https://github.com/rauchg/ms.js

local math = require('math')

--[[
 * Helpers.
 ]]

local s = 1000
local m = s * 60
local h = m * 60
local d = h * 24
local y = d * 365.25

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

--[[
 * Parse the given `str` and return milliseconds.
 *
 * @param {String} str
 * @return {Number}
 * @api private
]]

local function parse(str)
  if #str > 10000 then
    return
  end
  -- local match = /^((?:\d+)?\.?\d+) *(milliseconds?|msecs?|ms|seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d|years?|yrs?|y)?$/i.exec(str)
  local match = {}
  match[1], match[2] = str:match("(%d+)"), str:match("(%a+)$")
  if match == nil then
    return
  end
  local n = tonumber(match[1])
  local stype = (match[2] or 'ms'):lower()
  if stype:match('[years]*[year]*[yrs]*[yr]*[y]*') then
    return n * y
  end
  if stype:match('[days]*[dayr]*[d]*') then
    return n * d
  end
  if stype:match('[hours]*[hour]*[hrs]*[hr]*[h]*') then
    return n * h
  end
  if stype:match('[minutes]*[minute]*[mins]*[min]*[m]*') then
    return n * m
  end
  if stype:match('[seconds]*[second]*[secs]*[sec]*[s]*') then
    return n * s
  end
  if stype:match('[milliseconds]*[millisecond]*[msecs]*[msec]*[ms]*') then
    return n
  end
end

--[[
 * Short format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 ]]

local function short(ms)
  if (ms >= d) then return round(ms / d) .. 'd' end
  if (ms >= h) then return round(ms / h) .. 'h' end
  if (ms >= m) then return round(ms / m) .. 'm' end
  if (ms >= s) then return round(ms / s) .. 's' end
  return ms .. 'ms'
end

--[[
 * Pluralization helper.
 ]]

local function plural(ms, n, name)
  if (ms < n) then return end
  if (ms < n * 1.5) then return math.floor(ms / n) .. ' ' .. name end
  return math.ceil(ms / n) .. ' ' .. name .. 's'
end

--[[
 * Long format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 ]]

local function long(ms)
  return plural(ms, d, 'day')
    or plural(ms, h, 'hour')
    or plural(ms, m, 'minute')
    or plural(ms, s, 'second')
    or ms .. ' ms'
end


--[[
 * Parse or format the given `val`.
 *
 * Options:
 *
 *  - `long` verbose formatting [false]
 *
 * @param {String|Number} val
 * @param {Object} options
 * @return {String|Number}
 * @api public
 ]]

return function(val, options)
  options = options or {}
  if (type(val) == "string") then return parse(val) end
  if (options.long) then
    return long(val)
  else
    return short(val)
  end
end