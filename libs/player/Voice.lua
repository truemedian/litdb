local class = require('class')
local Emitter = require('utils/Emitter')
local enums = require('enums')
local Events = require('const').Events
local VoiceConnectState = enums.VoiceConnectState
local VoiceState = enums.VoiceState

---A voice channel handling class, most complex
---@class Voice: Emitter
---<!tag:interface>
---@field lunalink Core Main manager class
---@field guildId string Player's guild id
---@field shardId string ID of the Shard that contains the guild that contains the connected voice channel
---@field voiceId 'string/nil' Player's voice id
---@field state '[VoiceConnectState](Enumerations.md#voiceconnectstate)' Connection state
---@field deaf boolean Whether the player is deafened or not
---@field mute boolean Whether the player is muted or not
---@field lastvoiceId 'string/nil' ID of the last voiceId connected to
---@field region 'string/nil' Region of connected voice channel
---@field lastRegion 'string/nil' Last region of the connected voice channel
---@field serverUpdate ServerUpdate Cached serverUpdate event from Lavalink
---@field sessionId 'string/nil' ID of current session
---@field options VoiceChannelOptions Voice Options

local Voice, get = class('Voice', Emitter)

---Rainlink voice handler class
---@param lunalink Core
---@param voiceOptions VoiceChannelOptions
function Voice:__init(lunalink, voiceOptions)
  Emitter.__init(self)
  self._options = voiceOptions
  self._lunalink = lunalink
  self._guildId = voiceOptions.guildId
  self._voiceId = voiceOptions.voiceId
  self._deaf = voiceOptions.deaf or false
  self._mute = voiceOptions.mute or false
  self._shardId = voiceOptions.shardId
  self._lastVoiceId = nil
  self._region = nil
  self._lastRegion = nil
  self._sessionId = nil
end

function get:lunalink()
  return self._lunalink
end

function get:guildId()
  return self._guildId
end

function get:voiceId()
  return self._voiceId
end

function get:deaf()
  return self._deaf
end

function get:mute()
  return self._mute
end

function get:lastVoiceId()
  return self._lastVoiceId
end

function get:region()
  return self._region
end

function get:serverUpdate()
  return self._serverUpdate
end

function get:options()
  return self._options
end

function get:state()
  return self._state
end

function get:lastRegion()
  return self._lastRegion
end

function get:shardId()
  return self._shardId
end

function get:sessionId()
  return self._sessionId
end

---Connect from the voice channel
---@return Voice
function Voice:connect()
  if self._state == VoiceConnectState.CONNECTING or self._state == VoiceConnectState.CONNECTED then
    return self
  end
  self._state = VoiceConnectState.CONNECTING
  self:sendVoiceUpdate()
  self:debug('Requesting Connection')

  local timeout = self._lunalink.options.config.voiceConnectionTimeout
  local _, status = self:waitFor('connectionUpdate', timeout)

  if status == false then
    self:debug('Request Connection Failed')
    error(string.format("The voice connection is not established in %s ms", timeout))
  end

  assert(status ~= VoiceState.SESSION_ID_MISSING, 'The voice connection is not established due to missing session id')
  assert(status ~= VoiceState.SESSION_ENDPOINT_MISSING, 'The voice connection is not established due to missing connection endpoint')
  assert(status == VoiceState.SESSION_READY, 'Something went wrong with voice connection')

  self._state = VoiceConnectState.CONNECTED
  return self
end

---Send voice data to discord
---@return nil
function Voice:sendVoiceUpdate()
  self:sendDiscord({
    guild_id = self._guildId,
    channel_id = self._voiceId,
    self_deaf = self._deaf,
    self_mute = self._mute,
  })
end

---Send data to Discord
---@param data any
function Voice:sendDiscord(data)
  self._lunalink.library:sendPacket(self._shardId, 4, data)
end

---Sets the server update data for this connection
---@param data ServerUpdate
function Voice:setServerUpdate(data)
  if not data.endpoint then
    self:emit('connectionUpdate', VoiceState.SESSION_ENDPOINT_MISSING)
    return
  end

  if not self._sessionId then
    self:emit('connectionUpdate', VoiceState.SESSION_ID_MISSING)
    return
  end

  self._lastRegion = self._region
  self._region = self:_region_converter(data.endpoint) or nil

  if self._region and self._lastRegion ~= self._region then
    self:debug("Voice Region Moved | Old Region: %s New Region: %s", self._lastRegion, self._region)
  end

  self._serverUpdate = data

  self:emit('connectionUpdate', VoiceState.SESSION_READY)
  self:debug("Server Update Received | Server: %s", self._region)
end

---Update Session ID, Channel ID, Deafen status and Mute status of this instance
---@param data StateUpdatePartial
function Voice:setStateUpdate(data)
  self._lastVoiceId = self._voiceId or nil
  self._voiceId = data.channel_id

  if self._voiceId and self._lastVoiceId ~= self._voiceId then
    self:debug("Channel Moved | Old Channel: %s", self._voiceId)
  end

  if not self._voiceId then
    self._state = VoiceConnectState.DISCONNECTED
    self:debug('Channel Disconnected')
  end

  self._deaf = data.self_deaf
  self._mute = data.self_mute
  self._sessionId = data.session_id or nil
  self:debug("State Update Received | Channel: %s Session ID: %s", self._voiceId, data.session_id)
end

---Disconnect from the voice channel
---@return nil
function Voice:disconnect()
  self._voiceId = require('json').null
  self._deaf = false
  self._mute = false
  self:removeAllListeners()
  self:sendVoiceUpdate()
  self._state = VoiceConnectState.DISCONNECTED
  self:debug('Voice disconnected')
end

function Voice:_region_converter(data)
  local preres = {}
  for part in data:gmatch("([^%.]+)") do
    table.insert(preres, part)
  end

  local res = preres[1]

  return res:gsub("%d", "")
end

function Voice:debug(logs, ...)
	local pre_res = string.format(logs, ...)
	local res = string.format(
    '[Lunalink] / [Player @ %s] / [Voice] | %s',
    self._guildId,
    pre_res
  )
	self._lunalink:emit(Events.Debug, res)
end

return Voice