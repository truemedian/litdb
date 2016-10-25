--[[lit-meta
  name = 'voronianski/response-methods'
  description = 'Patch HTTP ServerResponse with useful response shortcut methods.'
  version = '1.0.0'
  homepage = 'https://github.com/luvitrocks/http-utils'
  repository = {
    url = 'http://github.com/luvitrocks/http-utils.git'
  }
  tags = {'http', 'server', 'methods', 'rest', 'api', 'response', 'utility', 'redirect', 'json', 'status'}
  dependencies = {
    'voronianski/mimes',
    'voronianski/file-type'
  },
  author = {
    name = 'Dmitri Voronianski',
    email = 'dmitri.voronianski@gmail.com'
  }
  license = 'MIT'
]]

local json = require('json')
local mimes = require('mimes')
local fileType = require('file-type')
local Buffer = require('buffer').Buffer
local ServerResponse = require('http').ServerResponse

local STATUS_CODES = {
  [100] = 'Continue',
  [101] = 'Switching Protocols',
  [102] = 'Processing',                 -- RFC 2518, obsoleted by RFC 4918
  [200] = 'OK',
  [201] = 'Created',
  [202] = 'Accepted',
  [203] = 'Non-Authoritative Information',
  [204] = 'No Content',
  [205] = 'Reset Content',
  [206] = 'Partial Content',
  [207] = 'Multi-Status',               -- RFC 4918
  [300] = 'Multiple Choices',
  [301] = 'Moved Permanently',
  [302] = 'Moved Temporarily',
  [303] = 'See Other',
  [304] = 'Not Modified',
  [305] = 'Use Proxy',
  [307] = 'Temporary Redirect',
  [400] = 'Bad Request',
  [401] = 'Unauthorized',
  [402] = 'Payment Required',
  [403] = 'Forbidden',
  [404] = 'Not Found',
  [405] = 'Method Not Allowed',
  [406] = 'Not Acceptable',
  [407] = 'Proxy Authentication Required',
  [408] = 'Request Time-out',
  [409] = 'Conflict',
  [410] = 'Gone',
  [411] = 'Length Required',
  [412] = 'Precondition Failed',
  [413] = 'Request Entity Too Large',
  [414] = 'Request-URI Too Large',
  [415] = 'Unsupported Media Type',
  [416] = 'Requested Range Not Satisfiable',
  [417] = 'Expectation Failed',
  [418] = "I'm a teapot",               -- RFC 2324
  [422] = 'Unprocessable Entity',       -- RFC 4918
  [423] = 'Locked',                     -- RFC 4918
  [424] = 'Failed Dependency',          -- RFC 4918
  [425] = 'Unordered Collection',       -- RFC 4918
  [426] = 'Upgrade Required',           -- RFC 2817
  [500] = 'Internal Server Error',
  [501] = 'Not Implemented',
  [502] = 'Bad Gateway',
  [503] = 'Service Unavailable',
  [504] = 'Gateway Time-out',
  [505] = 'HTTP Version not supported',
  [506] = 'Variant Also Negotiates',    -- RFC 2295
  [507] = 'Insufficient Storage',       -- RFC 4918
  [509] = 'Bandwidth Limit Exceeded',
  [510] = 'Not Extended'                -- RFC 2774
}

-- TO DO: use better way of detecting Buffer class
-- https://groups.google.com/forum/#!topic/luvit/RwnARiVm_XU
function _isBuffer (b)
  if type(b) == 'table' and type(b.inspect) == 'function' then
    local str = b:inspect()

    return type(str) == 'string' and str:find('<Buffer ')
  end

  return false
end

function ServerResponse:status (code)
  self.statusCode = code

  return self
end

function ServerResponse:send (body)
  local req = self.req
  local code = self.statusCode or 200
  local emptyContentType = not self:getHeader('Content-Type')

  self:writeHead(code, self.headers)

  if type(body) == 'string' then
    if emptyContentType then
      self:setHeader('Content-Type', 'text/html; charset=utf-8')
    end

    self:setHeader('Content-Length', #body)
  else
    if _isBuffer(body) then
      local fileTypeData = fileType(body)

      if fileTypeData and emptyContentType then
        self:setHeader('Content-Type', fileTypeData.mime)
      end

      self:setHeader('Content-Length', body.length)
      body = body:toString()
    else
      return self:json(body)
    end
  end

  -- strip irrelevant headers
  if self.statusCode == 204 or self.statusCode == 304 then
    self:removeHeader('Content-Type')
    self:removeHeader('Content-Length')
    self:removeHeader('Transfer-Encoding')
    body = '';
  end

  if body and req and req.method ~= 'HEAD' then
    self:write(body)
  end

  self:finish()

  collectgarbage()

  return self
end

function ServerResponse:json (...)
  if not self:getHeader('Content-Type') then
    self:setHeader('Content-Type', 'application/json')
  end

  return self:send(json.stringify(...))
end

function ServerResponse:redirect (code, url)
  if type(code) == 'string' then
    url = code
    code = 302
  end

  self:status(code):setHeader('Location', url)

  return self:send()
end

function ServerResponse:sendStatus (code)
  code = code or 200
  self:setHeader('Content-Type', 'text/plain')

  return self:status(code):send(STATUS_CODES[code])
end
