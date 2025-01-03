local class = require('class')
local json = require('json')
local AllowedPackets = { 'VOICE_STATE_UPDATE', 'VOICE_SERVER_UPDATE' }

---The interface class to make a custom library for audio node
---@class AbstractLibrary
---<!tag:interface>
---@field id string The bot ID
---@field shardCount string The bot shardCount for some audio node

local AbstractLibrary, get = class('AbstractLibrary')

function AbstractLibrary:__init(client)
  self._client = client
end

function get:id()
  error('Missing client id')
end

function get:shardCount()
  error('Missing client shardCount')
end

function AbstractLibrary:set(lunalink)
  self._lunalink = lunalink
  return self
end

---Listen attaches the event listener to the library you are using
---@param nodes 'table of [[LunalinkNodeOptions]]'
function AbstractLibrary:listen(nodes)
  error('Missing listen function')
end

---Where your library send packets to Discord Gateway
---@param shardId number The current shard Id
---@param payload any The payload data to request with discord gateway
---@param important boolean If this payload important or not
function AbstractLibrary:sendPacket(shardId, payload, important)
  error('Missing sendPacket function')
end

function AbstractLibrary:_ready(nodes)
  self._lunalink._id = self.id
  self._lunalink._shardCount = self.shardCount
  self._lunalink:emit(
    'debug',
    '[Lunalink] | Finished the initialization process | Now connect all current nodes'
  )
  for _, node in pairs(nodes) do
    self._lunalink._nodes:add(node)
  end
end

function AbstractLibrary:_raw(packet)
  packet = json.decode(packet)
  if not self:_includes(AllowedPackets, packet.t) then return end
  local guild_id = packet.d.guild_id
  local voice = self._lunalink._voices:get(guild_id)
  if not voice then return end
  if packet.t == 'VOICE_SERVER_UPDATE' then return voice:setServerUpdate(packet.d) end
  local user_id = packet.d.user_id
  if user_id ~= self._lunalink._id then return end
  voice:setStateUpdate(packet.d)
end

function AbstractLibrary:_includes(t, e)
  for _, value in pairs(t) do
		if value == e then
			return e
		end
	end
	return nil
end

return AbstractLibrary