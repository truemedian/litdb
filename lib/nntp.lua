local connect = require('coro-tcp').connect
local tlsWrap = require('coro-tls').wrap
local log = require('./log')

local _M = {}
local mt = { __index = _M }

local DOTEOL = ".\r\n"

function _M.new(self, opts)
  return setmetatable({opts = opts}, mt)
end

function _M.authenticate(self)
  local err = self:cmd(381, "AUTHINFO USER %s", self.opts.username)
  if err then return err end
  return self:cmd(281, "AUTHINFO PASS %s", self.opts.password)
end

function _M.cmd(self, expectCode, format, ...)
  local line, code, data
  line = string.format(format, ...)
  log('write', line)
  self.write(line .. '\r\n')
  data = self.read()
  code, line = string.match(data, "(...) (.*)")
  log('read', string.format("%d:%d", code, expectCode))
  if expectCode ~= tonumber(code) then return string.format("code: %d ~= %d", expectCode, code) end
  return nil, tonumber(code), line
end

function _M.group(self, group)
  self:cmd(211, "GROUP %s", group)
end

function _M.readBody(self, line)
  local buffer = { line }
  local data = self.read()
  repeat
    buffer[#buffer + 1] = data
    data = self.read()
  until data:sub(#data - 2) == DOTEOL
  log('readBody', 'done')
  return buffer
end

function _M.body(self, id)
  local err, _, line = self:cmd(222, "BODY %s", id)
  if err then return err end
  return self:readBody(line)
end

function _M.connect(self, port, host)
  local read, write = assert(connect(host, port))
  self.read, self.write = tlsWrap(read, write)
  local head = self.read()
  local code, banner = string.match(head, "(...) (.*)")
  assert(tonumber(code) == 200)
  if self.opts.username and self.opts.password then
    self:authenticate()
  end
  return nil, banner
end

return _M
