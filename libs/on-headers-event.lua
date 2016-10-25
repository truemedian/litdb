--[[lit-meta
  name = 'voronianski/on-headers-event'
  description = 'Add "headers" event and execute a listener when a response is about to write headers.'
  version = '1.0.0'
  homepage = 'https://github.com/luvitrocks/http-utils'
  repository = {
    url = 'http://github.com/luvitrocks/http-utils.git'
  }
  tags = {'http', 'server', 'methods', 'rest', 'api', 'on-headers', 'events'}
  author = {
    name = 'Dmitri Voronianski',
    email = 'dmitri.voronianski@gmail.com'
  }
  license = 'MIT'
]]

local ServerResponse = require('http').ServerResponse
local flushHeaders = ServerResponse.flushHeaders

function ServerResponse:flushHeaders (...)
  if not self.headers_sent then
    self:emit('headers', self)
  end

  flushHeaders(self, ...)
end
