--[[lit-meta
name = 'kaustavha/luvit-table'
version = '2.0.0'
license = 'MIT'
homepage = "https://github.com/kaustavha/luvit-table"
description = "Extends luas normal table with a few useful functions"
tags = {"luvit", "table"}
dependencies = { 
  "luvit/luvit@2",
  "luvit/tap"
}
author = { name = 'Kaustav Haldar'}
]]
local table = require('table')
exports.table = table

function tablePrint(tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, key .. " = {\n");
        table.insert(sb, tablePrint (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
        "%s = \"%s\"\n", tostring (key), tostring(value)))
      end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function toString(tbl)
  if  "nil"       == type( tbl ) then
    return tostring(nil)
  elseif  "table" == type( tbl ) then
    return tablePrint(tbl)
  elseif  "string" == type( tbl ) then
    return tbl
  else
    return tostring(tbl)
  end
end

function merge(...)
  local args = {...}
  local first = args[1] or {}
  for i,t in pairs(args) do
    if i ~= 1 and t then
      for k, v in pairs(t) do
        first[k] = v
      end
    end
  end

  return first
end

-- Return true if an item is in a table, false otherwise.
-- f - function which is called on every item and should return true if the item
-- matches, false otherwise
-- t - table
function contains(f, t)
  for _, v in ipairs(t) do
    if f(v) then
      return true
    end
  end

  return false
end

function deepCopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepCopy(orig_key)] = deepCopy(orig_value)
    end
    setmetatable(copy, deepCopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function valueToStr(v)
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type(v) and toString(v) or tostring(v)
  end
end

local function keyToStr( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. valueToStr( k ) .. "]"
  end
end

function tableToString(tbl, delim)
  local result, done = {}, {}
  local keys = {}

  delim = delim or ','

  for k, v in ipairs(tbl) do
    table.insert(result, tableValueToStr(v))
    done[ k ] = true
  end

  for k, v in pairs(tbl) do
    table.insert(keys, k)
  end

  table.sort(keys)

  for _, k in pairs(keys) do
    if not done[ k ] then
      table.insert(result, tableKeyToStr(k) .. "=" .. tableValueToStr(tbl[k]))
    end
  end
  return table.concat(result, delim)
end

local function safeMerge(a, b)
  if type(b) == 'string' then
    return table.insert(a, b)
  elseif type(b) == 'table' then
    return merge(a, b)
  elseif type(b) == 'nil' then
    return
  end
end

exports.table.safeMerge = safeMerge
exports.table.tableToString = tableToString
exports.table.tablePrint = tablePrint
exports.table.toString = toString
exports.table.merge = merge
exports.table.contains = contains
exports.table.deepCopy = deepCopy
exports.table.valueToStr = valueToStr
exports.table.keyToStr = keyToStr
