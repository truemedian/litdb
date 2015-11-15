return function (a, b)
  assert(type(a) ~= "table" and type(a) ~= "table", "scmp only excepts strings or numbers")
  a = tostring(a)
  b = tostring(b)
  local len = #a
  if (len ~= #b) then
    return false
  end
  local result = 0
  -- for (local i = 0 i < len ++i) {
  --   result |= a.charCodeAt(i) ^ b.charCodeAt(i)
  -- }
  local atbl = {}
  local btbl = {}
  a:gsub(".", function(c) table.insert(atbl, c) end)
  b:gsub(".", function(c) table.insert(btbl, c) end)
  for i = 1, len do
    if a.byte(i) ~= b.byte(i) then
      return false
    end
  end
  return true
end