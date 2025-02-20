local class = require('class')
local json = require('json')
local http = require('coro-http')
local websocket = require('utils/WebSocket')
local abstract = require('drivers/AbstractDriver')
local Functions = require('utils/Functions')
local NodelinkTwo, get = class('NodelinkTwo', abstract)

function NodelinkTwo:__init(lunalink, node)
  abstract.__init(self)
  self._lunalink = lunalink
  self._node = node
  self._id = 'nari'
  self._base_url_form = '%s://%s:%s/v4/%s'
  self._proto_list = node._options.secure
    and { http = 'https', ws = 'wss' }
    or { http = 'http', ws = 'ws' }
  self._wsUrl = string.format(
    self._base_url_form,
    self._proto_list.ws,
    node._options.host,
    node._options.port,
    'websocket'
  )
  self._httpUrl = string.format(
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

function NodelinkTwo:connect()
  local is_resume = self._lunalink._options.config.resume

  local client_name = string.format(
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

function NodelinkTwo:requester(options)
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

  if final_data.loadType then
    final_data = self:convertV4trackResponse(final_data)
  end

  self:debug("%s %s %s", req_method, url, req_body)

  return final_data or res_body_string
end

function NodelinkTwo:convertV4trackResponse(nl2Data)
  if not nl2Data then return {} end
  local ignore_list = { 'track', 'playlist', 'search', 'empty', 'error', 'shorts' }
  for _, value in pairs(ignore_list) do
    if nl2Data.loadType == value then return nl2Data
    else
      nl2Data.loadType = 'playlist'
      return nl2Data
    end
  end
end

function NodelinkTwo:wsClose()
  if self._wsClient then self._wsClient:close(1000, 'Self close') end
end

function NodelinkTwo:updateSession(sessionId, mode, timeout)
  self:debug('WARNING: Nodelink doesn\'t support resuming, set resume to true is useless')
end

function NodelinkTwo:getLyric(player, trackName, language)
  local track = player.queue.current and player.queue.current.encoded or nil
  if trackName then
    local nodeName = player.node.options.name
    local res = player:search(trackName, {
      nodeName = nodeName
    })
    if #res.tracks == 0 then return nil end
    track = res.tracks[1].encoded
  end
  return self:requester({
    path = '/loadlyrics',
    params = {
      encodedTrack = track,
      language = language and language or 'en',
    },
    headers = { { 'content-type', 'application/json' } },
    method = 'GET',
  })
end

return NodelinkTwo