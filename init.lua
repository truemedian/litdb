-- converted from https://github.com/joaquimserafim/base64-url
local Buffer = require('buffer').Buffer

local function unescape (str)
  local len = 4 - #str % 4
  local newstr = {}
  str:gsub("%S+", function(c) table.insert(newstr, c) end)
  for i = 1, len do
    table.insert(newstr, "")
  end
  newstr = table.concat(newstr, '=')
  newstr = newstr:gsub("(-)", "+")
  newstr = newstr:gsub("(_)", "/")
  return newstr
end

local function escape (str)
  str = str:gsub("(%+)", "-")
  str = str:gsub("(/)", "_")
  str = str:gsub("(%=)", "")
  return str
end

local function encode (str)
  return escape(Buffer:new(str):toString())
end

local function decode (str)
  return Buffer:new(unescape(str)):toString()
end

return {
  unescape = unescape,
  escape = escape,
  encode = encode,
  decode = decode
}