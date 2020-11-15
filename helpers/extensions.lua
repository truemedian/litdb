local sort, concat, insert, remove = table.sort, table.concat, table.insert, table.remove
local min, max, random, floor = math.min, math.max, math.random, math.floor
local char, gmatch, match, find, sub = string.char, string.gmatch, string.match, string.find, string.sub
local table = {}
table.count = function(tbl, fn)
  if fn == nil then fn = function() return true end end
  local n = 0
  for i, v in pairs(tbl) do if fn(i, v) then n = n + 1 end end
  return n
end
table.clone = function(tbl)
  local new = {}
  for i, v in pairs(tbl) do new[i] = v end
  return new
end
table.deepcount = function(tbl)
  local ret = {}
  for k, v in pairs(tbl) do ret[k] = type(v) == 'table' and table.deepcopy(v) or v end
  return ret
end
table.reverse = function(tbl) for i = 1, #tbl do insert(tbl, i, remove(tbl)) end end
table.reversed = function(tbl)
  local ret = {}
  for i = #tbl, 1, -1 do insert(ret, tbl[i]) end
  return ret
end
table.keys = function(tbl)
  local ret = {}
  for k in pairs(tbl) do insert(ret, k) end
  return ret
end
table.values = function(tbl)
  local ret = {}
  for _, v in pairs(tbl) do insert(ret, v) end
  return ret
end
table.randomipair = function(tbl)
  local i = random(#tbl)
  return i, tbl[i]
end
table.randompair = function(tbl)
  local rand = random(table.count(tbl))
  local n = 0
  for k, v in pairs(tbl) do
    n = n + 1
    if n == rand then return k, v end
  end
end
table.sorted = function(tbl, fn)
  local ret = {}
  for i, v in ipairs(tbl) do ret[i] = v end
  sort(ret, fn)
  return ret
end
table.search = function(tbl, value)
  for k, v in pairs(tbl) do if v == value then return k end end
  return nil
end
table.slice = function(tbl, start, stop, step)
  local ret = {}
  for i = start or 1, stop or #tbl, step or 1 do insert(ret, tbl[i]) end
  return ret
end
table.join = function(tbl, sep)
  local str = ''
  for _, v in pairs(tbl) do if type(v) ~= 'table' then str = str .. (v .. sep) end end
  return str
end
table.concatIndex = function(tbl, sep)
  local val = ''
  for i, _ in pairs(tbl) do val = tostring(val) .. tostring(i) .. tostring(sep) end
  return val:sub(0, #val - #sep)
end
local string = {}
string.split = function(str, delim)
  local ret = {}
  if not str then return ret end
  if not delim or delim == '' then
    for c in gmatch(str, '.') do insert(ret, c) end
    return ret
  end
  local n = 1
  while true do
    local i, j = find(str, delim, n)
    if not i then break end
    insert(ret, sub(str, n, i - 1))
    n = j + 1
  end
  insert(ret, sub(str, n))
  return ret
end
string.trim = function(str) return match(str, '^%s*(.-)%s*$') end
string.startswith = function(str, start) return str:sub(1, #start) == start end
string.endswith = function(str, End) return str:sub(#str - #End + 1, #str) == End end
string.random = function(len, mn, mx)
  if mn == nil then mn = 0 end
  if mx == nil then mx = 255 end
  local ret = {}
  for _ = 1, len do insert(ret, char(random(mn, mx))) end
  return concat(ret)
end
string.clamp = function(n, mn, mx) return min(max(n, mn), mx) end
local math = {}
math.clamp = function(n, minValue, maxValue) return min(max(n, minValue), maxValue) end
math.round = function(n, i)
  local m = 10 ^ (i or 0)
  return floor(n * m + 0.5) / m
end
local ext = setmetatable({table = table, string = string, math = math},
                         {__call = function(self) for _, v in pairs(self) do v() end end})
for n, m in pairs(ext) do setmetatable(m, {__call = function(self) for k, v in pairs(self) do _G[n][k] = v end end}) end
return setmetatable({}, {
  __call = function(self)
    ext.string()
    ext.math()
    return ext.table()
  end
})
