local URL = require('url')
local qs = require('querystring')

-- helper to find elements by its values
local function _indexOf (target, field)
  if type(target) == 'string' then
    return target:find(field, 1, true)
  end

  for index, value in pairs(target) do
    if value == field then return index end
  end

  return nil
end

-- list of supported methods to override
local function _supportMethod (method)
  local methods = {
    'get',
    'post',
    'put',
    'head',
    'delete',
    'options',
    'trace',
    'copy',
    'lock',
    'mkcol',
    'move',
    'propfind',
    'proppatch',
    'unlock',
    'report',
    'mkactivity',
    'checkout',
    'merge',
    'm-search',
    'notify',
    'subscribe',
    'unsubscribe',
    'patch'
  }

  return _indexOf(methods, method) ~= nil
end

-- create a getter for a given string
local function _createGetter (key)
  return function (req, res)
    if _indexOf(key:upper(), 'X-') == 1 then
      return req.headers[key:lower()] or ''
    else
      local parsedURL = URL.parse(req.url)

      if parsedURL.query and parsedURL.query ~= '' then
        local query = qs.parse(parsedURL.query)
        return query[key]
      end

      return ''
    end
  end
end

-- provides faux http method support
-- pass optional key param to use when checking for a method override, defaults to '_method'
local function methodOverride (key)
  key = key or 'X-HTTP-Method-Override'

  return function (req, res, nxt)
    req.originalMethod = req.originalMethod or req.method

    local get = _createGetter(key)
    local method = get(req, res)

    if _supportMethod(method:lower()) then
      req.method = method:upper()
    end

    nxt()
  end
end

return methodOverride
