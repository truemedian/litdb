exports.name = "james2doyle/string-trim"
exports.version = "0.0.1"
exports.homepage = "https://github.com/james2doyle/lit-string-trim"
-- plucked from https://github.com/luvit/luvit/wiki/Snippets

local gsub = require('string').gsub

local function trim(str, what)
  if (type(str) ~= 'string') then
    error("Expected string")
  end
  if what == nil then
    what = '%s+'
  end
  str = gsub(str, '^' .. what, '')
  str = gsub(str, what .. '$', '')
  return str
end

return trim