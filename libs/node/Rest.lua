local class = require('class')

---The rest class for get and calling from audio sending node/server REST API
---@class Rest
---<!tag:interface>
---@field lunalink Core The lunalink manager
---@field node Node The node manager (Node class)

local Rest, get = class('Rest')

local f = string.format

---The lavalink rest server handler class
---@param lunalink Core
---@param options LunalinkNodeOptions
---@param node Node
function Rest:__init(lunalink, options, node)
  self._lunalink = lunalink
  self._node = node
  self._options = options
  self._sessionId = self._node._driver._sessionId or ''
end

function get:node()
  return self._node
end

function get:lunalink()
  return self._lunalink
end

---Gets all the player with the specified sessionId
---@return '[GetPlayers](https://lavalink.dev/api/rest.html#get-players)'
function Rest:getPlayers()
  local options = {
    path = f('/sessions/%s/players', self._sessionId),
    headers = { { 'content-type', 'application/json' } },
  }
  return self._node._driver:requester(options)
end

---Gets current lavalink status
---@return '[getStatus](https://lavalink.dev/api/rest.html#get-lavalink-stats)'
function Rest:getStatus()
  local options = {
    path = '/stats',
    headers = { { 'content-type', 'application/json' } },
  }
  return self._node._driver:requester(options)
end

---Decode a single track from "encoded" properties
---@param encodedTrack string
---@return '[DecodeTrack](https://lavalink.dev/api/rest.html#track-decoding)'
function Rest:decodeTrack(encodedTrack)
  local options = {
    path = '/decodetrack',
    params = { encodedTrack = encodedTrack },
    headers = { { 'content-type', 'application/json' } },
  }
  return self._node._driver:requester(options)
end

---Updates a Lavalink player
---@param data UpdatePlayerInfo
---@return '[UpdatePlayer](https://lavalink.dev/api/rest.html#update-player)'
function Rest:updatePlayer(data)
  local options = {
    path = f('/sessions/%s/players/%s', self._sessionId, data.guildId),
    params = { noReplace = data.noReplace or 'false' },
    headers = { { 'content-type', 'application/json' } },
    method = 'PATCH',
    data = data.playerOptions,
    rawReqData = data,
  }
  return self._node._driver:requester(options)
end

---Destroy a Lavalink player
---@param guildId string
---@return '[DestroyPlayer](https://lavalink.dev/api/rest.html#destroy-player)'
function Rest:destroyPlayer(guildId)
  local options = {
    path = f('/sessions/%s/players/%s', self._sessionId, guildId),
    headers = { { 'content-type', 'application/json' } },
    method = 'DELETE',
  }
  return self._node._driver:requester(options)
end

---A track resolver function to get track from lavalink
---@param data string
---@return '[LoadResults](https://lavalink.dev/api/rest.html#load-result-type)'
function Rest:resolver(data)
  local options = {
    path = '/loadtracks',
    params = { identifier = data },
    headers = { { 'content-type', 'application/json' } }
  }
  return self._node._driver:requester(options)
end

---Get routeplanner status from Lavalink
---@return '[RoutePlannerStatus](https://lavalink.dev/api/rest.html#get-routeplanner-status)'
function Rest:getRoutePlannerStatus()
  local options = {
    path = '/routeplanner/status',
    headers = { { 'content-type', 'application/json' } },
  }
  return self._node._driver:requester(options)
end

---Release blacklisted IP address into pool of IPs
---@param address string
---@return '[UnmarkFailedAddress](https://lavalink.dev/api/rest.html#unmark-a-failed-address)'
function Rest:unmarkFailedAddress(address)
  local options = {
    path = '/routeplanner/free/address',
    headers = { { 'content-type', 'application/json' } },
    method = 'POST',
    data = { address },
  }
  return self._node._driver:requester(options)
end

---Get Lavalink info
---@return '[Info](https://lavalink.dev/api/rest.html#get-lavalink-info)'
function Rest:getInfo()
  local options = {
    path = '/info',
    headers = { { 'content-type', 'application/json' } },
  }
  return self._node._driver:requester(options)
end

return Rest