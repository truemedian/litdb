-- get index of field in table or character in string
function exports.indexOf (target, field)
  if type(target) == 'string' then
    return target:find(field, 1, true)
  end

  for index, value in pairs(target) do
    if value == field then
      return index
    end
  end

  return nil
end

-- last index of an element in string
function exports.lastIndexOf (str, elem)
  if type(str) ~= 'string' then
    error('string required')
  end

  local index = str:match('.*' .. elem .. '()')

  if not index then
    return nil
  else
    return index - 1
  end
end

-- split string
function exports.split (str, sep)
  sep = sep or '%s+'

  local result = {}
  local i = 1

  for value in str:gmatch('([^' .. sep .. ']+)') do
    result[i] = value
    i = i + 1
  end

  return result
end
