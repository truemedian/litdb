--[[lit-meta
  name = 'voronianski/match-path'
  description = 'Express.js style path matching for Luvit.io servers'
  version = '1.0.0'
  homepage = 'https://github.com/luvitrocks/http-utils'
  repository = {
    url = 'http://github.com/luvitrocks/http-utils.git'
  }
  tags = {'http', 'path', 'route', 'router', 'path-to-regexp', 'server', 'utopia', 'utopia-route'}
  author = {
    name = 'Dmitri Voronianski',
    email = 'dmitri.voronianski@gmail.com'
  }
  license = 'MIT'
]]

local quotepattern = '([' .. ('%^$().[]*+-?'):gsub('(.)', '%%%1') .. '])'
function escape(str)
  return str:gsub(quotepattern, '%%%1')
end

function compilePath (path)
  local parts = {'^'}
  local names = {}

  for a, b, c, d in path:gmatch('([^:]*):([_%a][_%w]*)(:?)([^:]*)') do
    if #a > 0 then
      parts[#parts + 1] = escape(a)
    end

    if #c > 0 then
      parts[#parts + 1] = '(.*)'
    else
      parts[#parts + 1] = '([^/]*)'
    end

    names[#names + 1] = b

    if #d > 0 then
      parts[#parts + 1] = escape(d)
    end
  end

  if #parts == 1 then
    return function (str)
      if str == path then
        return {}
      end
    end
  end

  parts[#parts + 1] = '$'

  local pattern = table.concat(parts)

  function getParams (str)
    local matches = { str:match(pattern) }

    if #matches > 0 then
      local results = {}

      for i = 1, #matches do
        results[names[i]] = matches[i]
      end

      return results
    end
  end

  return getParams
end

exports.compile = compilePath
