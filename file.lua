exports.name = "james2doyle/pretty-bytes"
exports.version = "0.0.2"
exports.homepage = "https://github.com/james2doyle/lit-pretty-bytes"
-- converted from https://github.com/sindresorhus/pretty-bytes

local math = require('math')

-- rounds a number to the given number of decimal places.
function round(num, idp)
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function prettyBytes(num, space)
  if (type(num) ~= 'number') then
    error('Expected a number')
  end

  local units = {'B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'}

  if space == nil then
    space = ''
  else
    space = ' '
  end

  if (num < 1) then
    return num .. ' B'
  end

  local exponent = math.min(math.floor(math.log(num) / math.log(1000)), #units)
  local num = round((num / math.pow(1000, exponent)), 2) * 1
  -- add 1 to compentsate for 1 indexed arrays
  local unit = units[exponent + 1]

  return num .. space .. unit
end

return prettyBytes