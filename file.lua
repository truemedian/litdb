--[[lit-meta
  name = 'voronianski/response-methods'
  description = 'Patch HTTP ServerResponse with useful response shortcut methods.'
  version = '1.0.0'
  homepage = 'https://github.com/luvitrocks/http-utils'
  repository = {
    url = 'http://github.com/luvitrocks/http-utils.git'
  }
  tags = {'http', 'server', 'methods', 'rest', 'api', 'response', 'utility', 'redirect', 'json', 'status'}
  author = {
    name = 'Dmitri Voronianski',
    email = 'dmitri.voronianski@gmail.com'
  }
  license = 'MIT'
]]

local ServerResponse = require('http').ServerResponse
local json = require('json')

function _extend (obj, with_obj)
  for k, v in pairs(with_obj) do
    obj[k] = v
  end

  return obj
end

function ServerResponse:status (code)
  self.statusCode = code

  return self
end

function ServerResponse:send (body)
  local code = self.statusCode or 200
  local headers = _extend({
    ['Content-Type'] = 'text/html; charset=utf-8',
    ['Content-Length'] = body and #body or 0
  }, self.headers)

  self:writeHead(code, headers)

  if body then
    self:write(body)
  end

  self:finish()
  collectgarbage()
end

function ServerResponse:json (tbl)
  self:setHeader('Content-Type', 'application/json')
  self:finish(json.stringify(tbl, opts))

  return self
end

function ServerResponse:redirect (code, url)
  if type(code) == 'string' then
    url = code
    code = 302
  end

  self:status(code):setHeader('Location', url)
  self:send()

  return self
end
