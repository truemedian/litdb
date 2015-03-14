--[[
Copyright 2015 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]
local JSON = require('json')
local KeystoneClient = require('keystone-client').Client
local Object = require('core').Object
local async = require('async')
local errors = require('./errors')
local fmt = require('string').format
local misc = require('./misc')
local request = require('request').request
local string = require('string')
local table = require('table')

local MAAS_CLIENT_KEYSTONE_URL
local MAAS_CLIENT_DEFAULT_HOST

if process.env.STAGING then
  MAAS_CLIENT_KEYSTONE_URL = 'https://staging.identity.api.rackspacecloud.com/v2.0/tokens'
  MAAS_CLIENT_DEFAULT_HOST = 'https://staging.monitoring.api.rackspacecloud.com/v1.0'
else
  MAAS_CLIENT_KEYSTONE_URL = 'https://identity.api.rackspacecloud.com/v2.0/tokens'
  MAAS_CLIENT_DEFAULT_HOST = 'https://monitoring.api.rackspacecloud.com/v1.0'
end

--[[ ClientBase ]]--

local ClientBase = Object:extend()
function ClientBase:initialize(host, options)
  self.host = host
  self.tenantId = nil
  self._mfaCallback = nil
  self.options = misc.merge({}, options)
  self.headers = {}
  table.insert(self.headers, { 'user-agent', options.user_agent or 'agent/luvit-keystone-client' })
  table.insert(self.headers, { 'content-type', 'application/json' })
  table.insert(self.headers, { 'transfer-encoding', 'chunked' })
end

function ClientBase:setToken(token, expiry)
  table.insert(self.headers, { 'x-auth-token', token })
  self.token = token
  self._tokenExpiry = expiry
end

function ClientBase:setTenantId(tenantId)
  self.tenantId = tenantId
end

function ClientBase:_parseResponse(data, callback)
  local parsed = JSON.parse(data)
  callback(nil, parsed)
end

function ClientBase:_parseData(data)
  local res = {
    xpcall(function()
      return JSON.parse(data)
    end, function(e)
      return e
    end)
  }
  if res[1] == false then
    return res[2]
  else
    return JSON.parse(res[2])
  end
end

function ClientBase:request(method, path, payload, expectedStatusCode, callback)
  -- setup payload
  local extraHeaders = {}
  if payload then
    if type(payload) == 'table' and self.headers['Content-Type'] == 'application/json' then
      payload = JSON.stringify(payload)
    end
    table.insert(extraHeaders, { 'content-length', #payload })
  end

  -- setup path
  if self.tenantId then
    path = fmt('%s/%s%s', self.host, self.tenantId, path)
  else
    path = fmt('%s/%s', self.host, path)
  end

  local headers = misc.merge(self.headers, extraHeaders)
  local options = {
    url = path,
    headers = headers,
    method = method,
    body = payload
  }

  if process.env.HTTP_PROXY then
    options.proxy = process.env.HTTP_PROXY
  elseif process.env.HTTPS_PROXY then
    options.proxy = process.env.HTTPS_PROXY
  end

  request(options, function(err, res)
    local data = ''
    res:on('data', function(chunk)
      data = data .. chunk
    end)
    res:on('end', function()
      self._lastRes = res
      if res.statusCode ~= expectedStatusCode then
        callback(errors.HttpResponseError:new(res.statusCode, method, path, data))
      else
        if res.statusCode == 200 then
          self:_parseResponse(data, callback)
        elseif res.statusCode == 201 or res.statusCode == 204 then
          callback(nil, res.headers['location'])
        else
          data = self:_parseData(data)
          callback(errors.HttpResponseError:new(res.statusCode, method, path, data))
        end
      end
    end)
  end)
end

--[[ Client ]]--

local Client = ClientBase:extend()
function Client:initialize(userId, key, options)
  options = options or {}
  self.userId = userId
  self.key = key
  self.authUrl = options.authUrl
  self.entities = {}
  self.checks = {}
  self.agent_tokens = {}
  self:_init()
  ClientBase.initialize(self, MAAS_CLIENT_DEFAULT_HOST, options)
end

function Client:_init()
  self.entities.create = function(params, callback)
    self:request('POST', '/entities', params, 201, function(err, entityUrl)
      if err then
        callback(err)
        return
      end
      callback(nil, string.match(entityUrl, 'entities/(.*)'))
    end)
  end

  self.entities.update = function(id, params, callback)
    self:request('PUT', fmt('/entities/%s', id), params, 204, function(err, entityUrl)
      if err then
        callback(err)
        return
      end
      callback(nil, string.match(entityUrl, 'entities/(.*)'))
    end)
  end

  self.entities.list = function(callback)
    self:requestPaginated('/entities', callback)
  end

  self.checks.create = function(entity, params, callback)
    self:request('POST', fmt('/entities/%s/checks', entity), params, 201, function(err, entityUrl)
      if err then
        callback(err)
        return
      end
      callback(nil, string.match(entityUrl, fmt('entities/%s/checks/(.*)', entity)))
    end)
  end

  self.checks.update = function(entity, params, callback)
    self:request('POST', fmt('/entities/%s/checks', entity), params, 204, function(err, entityUrl)
      if err then
        callback(err)
        return
      end
      callback(nil, string.match(entityUrl, fmt('entities/%s/checks/(.*)', entity)))
    end)
  end

  self.checks.list = function(id, callback)
    self:requestPaginated(fmt('/entities/%s/checks', id), callback)
  end

  self.agent_tokens.get = function(callback)
    self:request('GET', '/agent_tokens', nil, 200, callback)
  end

  self.agent_tokens.create = function(options, callback)
    local body = {}
    body['label'] = options.label
    self:request('POST', '/agent_tokens', body, 201, function(err, tokenUrl)
      if err then
        callback(err)
        return
      end
      callback(nil, string.match(tokenUrl, 'agent_tokens/(.*)'))
    end)
  end
end

function Client:setMFACallback(callback)
  self._mfaCallback = callback
end

function Client:auth(authUrls, username, keyOrPassword, callback)
  local provider = 'cloudMonitoring'
  local client = KeystoneClient:new(MAAS_CLIENT_KEYSTONE_URL, { username = username, apikey = keyOrPassword })
  client:setMFACallback(self._mfaCallback)
  client:tenantIdAndToken(provider, function(err, obj)
    if err then
      client = KeystoneClient:new(MAAS_CLIENT_KEYSTONE_URL, { username = username, password = keyOrPassword })
      client:setMFACallback(self._mfaCallback)
      client:tenantIdAndToken(provider, callback)
      return
    end
    callback(nil, obj)
  end)
end

--[[
The request.
callback.function(err, results)
]]--
function Client:request(method, path, payload, expectedStatusCode, callback)
  local authUrls = self.authUrl and { self.authUrl } or { MAAS_CLIENT_KEYSTONE_URL }
  local results

  async.waterfall({
    function(callback)
      if self:tokenValid() then
        callback()
        return
      end
      self:auth(authUrls, self.userId, self.key, function(err, obj)
        if err then
          return callback(err)
        end
        self:setToken(obj.token, obj.expires)
        self:setTenantId(obj.tenantId)
        callback()
      end)
    end,

    function(callback)
      ClientBase.request(self, method, path, payload, expectedStatusCode, function(err, obj)
        if not err then
          results = obj
        end
        callback(err)
      end)
    end
  }, function(err)
    callback(err, results)
  end)
end

--[[
The request.
callback.function(err, results)
]]--
function Client:requestPaginated(path, callback)
  local startMarker = nil
  local firstRun = true
  local results = {}

  async.whilst(function()
    if firstRun == true then
      firstRun = false
      return true
    end

    if startMarker ~= nil then
      return true
    end

    return false
  end,

  function(callback)
    local exPath = path

    if startMarker ~= nil then
      exPath = fmt('%s?marker=%s', exPath, startMarker)
    end

    self:request('GET', exPath, nil, 200, function (err, data)
      if err then
        return callback(err)
      end

      startMarker = data.metadata.next_marker

      for k, v in pairs(data.values) do
        table.insert(results, v)
      end

      callback(nil)
    end)
  end,

  function(err)
    -- Keeps API compataible to wrap the values  here.
    callback(err, {values = results})
  end)
end

function Client:tokenValid()
  if self.token then
    return true
  end
  return false
end

exports.Client = Client
