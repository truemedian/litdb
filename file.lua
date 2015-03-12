exports.name = "james2doyle/pretty-bytes"
exports.version = "0.0.1"
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

  local neg = num < 0
  local units = {'B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'}

  if (neg == nil) then
    num = -num
  end

  if space == nil then
    space = ''
  else
    space = ' '
  end

  if (num < 1) then
    if neg ~= nil then
      return num .. ' B'
    else
      return '-' .. num .. ' B'
    end
  end

  local exponent = math.min(math.floor(math.log(num) / math.log(1000)), #units)
  local num = round((num / math.pow(1000, exponent)), 2) * 1
  -- add 1 to compentsate for 1 indexed arrays
  local unit = units[exponent + 1]

  if neg ~= nil then
    return num .. space .. unit
  else
    return '-' .. num .. space .. unit
  end
end

return prettyBytes