--[[
Copyright 2012 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]--

local Emitter = require('core').Emitter
local math = require('math')
local timer = require('timer')
local fmt = require('string').format

local async = require('async')

local ConnectionMessages = require('./connection_messages').ConnectionMessages

local AgentClient = require('./client').AgentClient
local consts = require('../util/constants')
local logging = require('logging')
local misc = require('../util/misc')
local upgrade = require('../client/upgrade')
local vutils = require('../utils')

local ConnectionStream = Emitter:extend()
function ConnectionStream:initialize(id, token, guid, upgradeEnabled, options, types, features, codeCert)
  self._id = id
  self._token = token
  self._guid = guid
  self._channel = nil
  self._clients = {}
  self._unauthedClients = {}
  self._delays = {}
  self._activeTimeSyncClient = nil
  self._upgradeEnabled = upgradeEnabled
  self._options = options or {}
  self._types = types or {}
  self._features = features or {}
  self._messages = ConnectionMessages:new(self)
  self._isUpgrading = false
  self._codeCert = codeCert
end

function ConnectionStream:getMessages()
  return self._messages
end

function ConnectionStream:setChannel(channel)
  self._channel = channel or consts:get('DEFAULT_CHANNEL')
end

function ConnectionStream:getChannel()
  return self._channel
end

function ConnectionStream:performUpgrade()
  if self._isUpgrading == true then
    logging.debug('Agent is already upgrading')
    return
  end

  logging.info('Upgrade Request')
  self._isUpgrading = true

  local status, err = pcall(upgrade.checkForUpgrade, self._codeCert, self, function(err, status)
    self._isUpgrading = false
    if err then
      logging.error('Error on upgrade: ' .. misc.trim(tostring(err)))
      return
    end
    self:emit('upgrade.success')
  end)

  if not status then
    self._isUpgrading = false
    logging.error('Check For Upgrade Failed: ' .. misc.trim(tostring(err)))
  end
end

--[[
Create and establish a connection to the multiple endpoints.

addresses - An Array of ip:port pairs
callback - Callback called with (err) when all the connections have been
established.
--]]
function ConnectionStream:createConnections(endpoints, callback)
  local iter = function(endpoint, callback)
    self:createConnection({endpoint = endpoint}, callback)
  end

  async.series({
    -- connect
    function(callback)
      async.forEach(endpoints, iter, callback)
    end
  }, callback)
end

function ConnectionStream:clearDelay(datacenter)
  if self._delays[datacenter] then
    self._delays[datacenter] = nil
  end
end

--[[
Create and establish a connection to the endpoint.

datacenter - Datacenter name / host alias.
host - Hostname.
port - Port.
callback - Callback called with (err)
]]--
function ConnectionStream:_createConnection(options)
  local clientType = self._types.AgentClient or AgentClient
  local client = clientType:new(options, self, self._types)
  client:on('error', function(errorMessage)
    local err = {}
    err.ip = options.ip
    err.host = options.host
    err.port = options.port
    err.datacenter = options.datacenter
    err.message = errorMessage
    client:log(logging.DEBUG, fmt('client error: %s', err.message))
    client:destroy(err)
  end)

  client:on('respawn', function()
    client:log(logging.DEBUG, 'Respawning client')
    self:_restart(client, options)
  end)

  client:on('timeout', function()
    client:log(logging.DEBUG, 'Client Timeout')
    client:destroy()
  end)

  client:on('connect', function()
    client:getMachine():react(client, 'connect')
  end)

  client:on('end', function()
    self:emit('client_end', client)
    client:log(logging.DEBUG, 'Remote endpoint closed the connection')
    client:destroy()
  end)

  client:on('handshake_success', function(data)
    self:emit('handshake_success')
    client:getMachine():react(client, 'handshake_success')
    self._messages:emit('handshake_success', client, data)
 end)

  client:on('message', function(msg)
    self._messages:emit('message', client, msg)
    client:getMachine():react(client, 'message', msg)
  end)

  client:setDatacenter(options.datacenter)
  self._unauthedClients[client:getDatacenter()] = client

  return client
end

function ConnectionStream:_setDelay(datacenter)
  local previousDelay = self._delays[datacenter]

  if previousDelay == nil then
    previousDelay = misc.calcJitter(consts:get('DATACENTER_FIRST_RECONNECT_DELAY'),
                                    consts:get('DATACENTER_FIRST_RECONNECT_DELAY_JITTER'))
  end

  local delay = math.min(previousDelay, consts:get('DATACENTER_RECONNECT_DELAY'))
  delay = misc.calcJitter(delay, consts:get('DATACENTER_RECONNECT_DELAY_JITTER'))
  self._delays[datacenter] = delay
  return delay
end

--[[
Retry a connection to the endpoint.

options - datacenter, endpoint
  datacenter - Datacenter name / host alias.
  endpoint - Endpoint Structure containing SRV query or hostname/port.
callback - Callback called with (err)
]]--
function ConnectionStream:reconnect(options)
  local datacenter = options.datacenter
  local delay = self:_setDelay(datacenter)
  local onTimer

  if self._shutdown then return end

  logging.infof('%s -> Retrying connection in %dms',
                datacenter, delay)

  function onTimer()
    local onCreate

    function onCreate(err)
      if err then
        logging.errorf('%s -> Error reconnecting (%s)',
          datacenter, tostring(err))
      end
    end

    self:createConnection(options, onCreate)
  end

  self:emit('reconnect', options)
  self._reconnect_timer = timer.setTimeout(delay, onTimer)
end

--[[
Restart a client that has failed on error, timeout, or end

client - client that needs restarting
options - passed to ConnectionStream:reconnect
callback - Callback called with (err)
]]--
function ConnectionStream:_restart(client, options, callback)
  -- The error we hit was rateLimit related.
  -- Shut down the agent.
  if client.rateLimitReached then
    self:emit('shutdown', consts:get('SHUTDOWN_RATE_LIMIT'))
    return
  end
  self:reconnect(options, callback)
end

function ConnectionStream:shutdown()
  if self._reconnect_timer then timer.clearTimeout(self._reconnect_timer) end
  self._shutdown = true
  self:done()
end

function ConnectionStream:done()
  for k, v in pairs(self._clients) do
    v:destroy()
  end
end

function ConnectionStream:getClient()
  local client
  local latency
  local min_latency = 2147483647
  for k, v in pairs(self._clients) do
    if not self._clients[k]:isDestroyed() then
      latency = self._clients[k]:getLatency()
      if latency == nil then
        client = self._clients[k]
      elseif min_latency > latency then
        client = self._clients[k]
        min_latency = latency
      end
    end
  end
  return client
end

function ConnectionStream:isTimeSyncActive()
  return self._activeTimeSyncClient ~= nil
end

function ConnectionStream:getActiveTimeSyncClient()
  return self._activeTimeSyncClient
end

function ConnectionStream:setActiveTimeSyncClient(client)
  self._activeTimeSyncClient = client
  self:_attachTimeSyncEvent(client)
end

--[[
The algorithm for syncing time follows:

Note: Promoted clients have been handshake accepted to the endpoint.

1. On promotion, attach a time_sync event to the client
2. If a client disconnects and it is the time sync client then find
   a new client to perform time syncs
]]--
function ConnectionStream:_attachTimeSyncEvent(client)
  if not client then
    return
  end
  client:on('time_sync', function(timeObj)
    vutils.timesync(timeObj.agent_send_timestamp, timeObj.server_receive_timestamp,
                   timeObj.server_response_timestamp, timeObj.agent_recv_timestamp)
  end)
end

--[[
Move an unauthenticated client to the list of clients that have been authenticated.
client - the client.
]]--
function ConnectionStream:promoteClient(client)
  local datacenter = client:getDatacenter()
  client:log(logging.INFO, fmt('Connection has been authenticated to %s', datacenter))
  self._clients[datacenter] = client
  self._unauthedClients[datacenter] = nil
  self:emit('promote', self)
end

--[[
Create and establish a connection to the endpoint.

datacenter - Datacenter name / host alias.
host - Hostname.
port - Port.
callback - Callback called with (err)
]]--
function ConnectionStream:createConnection(options, callback)
  local opts = misc.merge({
    endpoint = options.endpoint,
    features = self._features,
    id = self._id,
    datacenter = tostring(options.endpoint),
    token = self._token,
    guid = self._guid,
    timeout = consts:get('CONNECT_TIMEOUT')
  }, self._options, options)

  opts.endpoint:getHostInfo(function(err, host, ip, port)
    if err then
      logging.errorf('%s -> Error resolving (%s)',
        options.datacenter, tostring(err))
      self:reconnect(opts, callback)
      return
    end

    opts.ip = ip
    opts.host = host
    opts.port = port

    local client = self:_createConnection(opts)
    client:connect()
    callback()
  end)
end

function ConnectionStream:getEntityId()
  return self:getClient()._entity_id
end

exports.ConnectionStream = ConnectionStream
