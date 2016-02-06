-- converted from: https://github.com/jshttp/cookie/blob/master/index.js

local char = require('string').char
local byte = require('string').byte
local gmatch = require('string').gmatch
local format = require('string').format
local push = require('table').insert
local join = require('table').concat

local function unescape(s)
  s = s:gsub("+", " ")
  s = s:gsub("%%(%x%x)", function (h)
    return char(tonumber(h, 16))
    end)
  return s
end

local function escape(s)
  s = s:gsub("([&=+%c])", function (c)
    return format("%%%02X", byte(c))
    end)
  s = s:gsub(" ", "+")
  return s
end

local function trim(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

local function decode(s)
  local results = {}
  if s:find("=%b\"\"") == nil then
    for key, value in gmatch(s, "([^&=]+)=([^&=]+)") do
      -- trim
      key = trim(key)
      value = trim(value)
      key = unescape(key)
      value = unescape(value)
      results[key] = value
    end
  else
    -- handle nested values
    s:gsub("([^&=]+)=(%b\"\")", function( key, value )
      -- trim
      key = trim(key)
      value = trim(value)
      -- remove outside quotes
      value = value:sub(2, (#value - 1))
      results[key] = decode(value)
    end)
  end
  return results
end

local function encode(t)
  if type(t) ~= 'table' then
    return escape(t)
  else
    local s = ""
    for k,v in pairs(t) do
      s = s .. "&" .. escape(k) .. "=" .. escape(v)
    end
    -- remove first `&'
    return s:sub(2)
  end
end

local function try_decode(val)
  local decoded = decode(val)
  if type(decoded) == 'table' then
    return decoded
  else
    return val
  end
end

-- Parse the cookie header string and return a table
-- -- cookie.parse('foo=%1;bar=bar;HttpOnly;Secure')

local function parse(str)
  if (type(str) ~= 'string') then
    error('argument must be a string')
  end

  -- if we dont have a semi-colon at the end, just add one
  if str:find(";") ~= #str then
    str = str .. ";"
  end

  local obj = {}
  -- split by semi-colon
  str:gsub("([^%;]*)%;", function(line)
    local dec = try_decode(line)
    if next(dec) ~= nil then
      -- merge the table in
      for k,v in pairs(dec) do obj[k] = v end
    end
  end)

  return obj
end

-- Serialize the name=value pair into a cookie string suitable for
-- http headers. An optional options object specified cookie parameters.
-- -- serialize('foo', 'bar', { httpOnly: true })

local function serialize(name, val, options)
  local opt = options or {}
  local results = { name .. '=' .. encode(val) }

  if (opt.maxAge ~= nil) then
    if (type(opt.maxAge) ~= 'number') then
      error('maxAge should be a Number')
    else
      local maxAge = opt.maxAge - 0
      push(results, 'Max-Age=' .. maxAge)
    end
  end

  if (opt.domain) then
    push(results, 'Domain=' .. opt.domain)
  end
  if (opt.path) then
    push(results, 'Path=' .. opt.path)
  end
  if (opt.expires) then
    push(results, 'Expires=' .. tostring(opt.expires))
  end
  if (opt.httpOnly) then
    push(results, 'HttpOnly')
  end
  if (opt.secure) then
    push(results, 'Secure')
  end
  if (opt.firstPartyOnly) then
    push(results, 'First-Party-Only')
  end

  return join(results, '; ')
end

return {
  parse = parse,
  serialize = serialize
}