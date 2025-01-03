local class = require('class')
local json = require('json')
local http = require('coro-http')
local websocket = require('utils/WebSocket')
local abstract = require('drivers/AbstractDriver')
local Functions = require('utils/Functions')
local LavalinkFour, get = class('LavalinkFour', abstract)
local sf = string.format

function LavalinkFour:__init(lunalink, node)
  abstract.__init(self)
  self._lunalink = lunalink
  self._node = node
  self._id = 'koinu'
  self._base_url_form = '%s://%s:%s/v4/%s'
  self._proto_list = node._options.secure
    and { http = 'https', ws = 'wss' }
    or { http = 'http', ws = 'ws' }
  self._wsUrl = sf(
    self._base_url_form,
    self._proto_list.ws,
    node._options.host,
    node._options.port,
    'websocket'
  )
  self._httpUrl = sf(
    self._base_url_form,
    self._proto_list.http,
    node._options.host,
    node._options.port,
    ''
  ):sub(1, -2)
  self._sessionId = ''
  self._playerFunctions = Functions()
  self._functions = Functions()
  self._wsClient = nil
end

function get:id()
  return self._id
end

function get:wsUrl()
  return self._wsUrl
end

function get:httpUrl()
  return self._httpUrl
end

function get:sessionId()
  return self._sessionId
end

function get:playerFunctions()
  return self._playerFunctions
end

function get:functions()
  return self._functions
end

function get:lunalink()
  return self._lunalink
end

function get:node()
  return self._node
end

function LavalinkFour:connect()
  local is_resume = self._lunalink._options.config.resume

  local client_name = sf(
    '%s/%s (%s)',
    self._lunalink._manifest.name,
    self._lunalink._manifest.version,
    self._lunalink._manifest.github
  )

  local headers = {
    { 'authorization', self._node._options.auth },
    { 'user-id', self._lunalink._id },
    { 'client-name', client_name },
    { 'user-agent', self._lunalink._options.config.userAgent },
    { 'num-shards', self._lunalink._shardCount },
  }

  if self._sessionId ~= nil and is_resume then
    table.insert(headers, { 'session-id', self._sessionId })
  end

  self._wsClient = websocket({
    url = self._wsUrl,
    headers = headers
  })

  self._wsClient:on('open', function ()
    self._node:wsOpenEvent()
  end)

  self._wsClient:on('message', function (data)
    self._node:wsMessageEvent(data.json_payload)
  end)

  self._wsClient:on('close', function (code, reason)
    self._node:wsCloseEvent(code, reason)
  end)

  self._wsClient:on('error', function (err)
    self._node:wsErrorEvent(err)
    self._wsClient = nil
  end)

  self._wsClient:connect()
end

function LavalinkFour:requester(options)
  options = options or {}
  local req_body = ''
  if string.match(options.path ,'/sessions') and self._sessionId == nil then
    error('sessionId not initalized! Please wait for lavalink get connected!')
  end
  local url = self._httpUrl .. options.path

  if options.params then url = url .. self:_urlparams(options.params) end
  if options.data then req_body = json.encode(options.data) end

  local lavalink_headers = {
    { 'authorization', self._node._options.auth },
    { 'user-agent', self._lunalink._options.config.userAgent },
    table.unpack(options.headers and options.headers or {})
  }

  local req_method = options.method and options.method or 'GET'

  local res, res_body_string = http.request(req_method, url, lavalink_headers, req_body)

  if res.code == 204 then
    self:debug("%s %s %s", req_method, url, req_body)
    return nil
  end

  if res.code ~= 200 then
    self:debug("%s %s %s", req_method, url, req_body)
    self:debug(
      'Something went wrong with lavalink server. '
      .. 'Status code: %s\n Headers: %s',
      res.code, json.encode(options.headers)
    )
    return nil
  end

  local final_data = json.decode(res_body_string)

  self:debug("%s %s %s", req_method, url, req_body)

  return final_data or res_body_string
end

function LavalinkFour:wsClose()
  if self._wsClient then self._wsClient:close(1000, 'Self close') end
end

function LavalinkFour:updateSession(sessionId, mode, timeout)
  error('driver function: updateSession missing')
  local options = {
    path = sf('/sessions/%s', sessionId),
    headers = {
      { 'content-type', 'application/json' },
    },
    method = 'PATCH',
    data = {
      resuming = mode,
      timeout = timeout,
    }
  }
  self:debug("Session updated! resume: %s, timeout: %s", mode, timeout)
  self:requester(options)
end

return LavalinkFour