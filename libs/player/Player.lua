local class = require('class')
local Queue = require('player/Queue')
local Cache = require('utils/Cache')
local AudioFilter = require('player/AudioFilter')
local Functions = require('utils/Functions')
local enums = require('enums')
local Events = require('const').Events
local LoopMode = enums.LoopMode
local PlayerState = enums.PlayerState
local VoiceConnectState = enums.VoiceConnectState
local json = require('json')
local NULL = json.null

---A class for managing player action.
---@class Player
---<!tag:interface>
---@field lunalink Core Main manager class
---@field node Node Player's current using lavalink server
---@field guildId string Player's guild id
---@field voiceId 'string/nil' Player's voice id
---@field textId string Player's text id
---@field queue Queue Player's queue
---@field data Cache The temporary database of player, u can set any thing here and us like Map class!
---@field paused boolean Whether the player is paused or not
---@field position number Get the current track's position of the player
---@field volume number Get the current volume of the player
---@field playing boolean Whether the player is playing or not
---@field loop '[LoopMode](Enumerations.md#loopmode)' Get the current loop mode of the player
---@field state '[PlayerState](Enumerations.md#playerstate)' Get the current state of the player
---@field deaf boolean Whether the player is deafened or not
---@field mute boolean Whether the player is muted or not
---@field track string ID of the current track
---@field functions Functions All function to extend support driver
---@field shardId string ID of the Shard that contains the guild that contains the connected voice channel
---@field filter AudioFilter Filter class to set, clear get the current filter data
---@field voice Voice Voice handler class
-- @field _sudoDestroy Core Main manager class

local Player, get = class('Player')

---Initial function for Player class
---@param lunalink Core
---@param voice Voice
---@param node Node
function Player:__init(lunalink, voice, node)
  self._sudoDestroy = false
  self._voice = voice
  self._lunalink = lunalink
  local lunalink_config = self._lunalink.options.config
  self._guildId = voice.guildId
  self._voiceId = voice.voiceId
  self._shardId = voice.shardId
  self._mute = voice.mute or false
  self._deaf = voice.deaf or false
  self._node = node
  self._guildId = voice.guildId
  self._voiceId = voice.voiceId
  self._textId = voice.options.textId
  local customQueue = lunalink_config.structures and lunalink_config.structures.queue
  self._queue = customQueue
    and lunalink_config.structures.queue(lunalink, self)
    or Queue(lunalink, self)
  self._data = Cache()
  if lunalink_config.structures and lunalink_config.structures.filter then
    self._filter = lunalink_config.structures.filter(self)
  else self._filter = AudioFilter(self) end
  self._volume = lunalink_config.defaultVolume
  self._loop = LoopMode.NONE
  self._state = PlayerState.DESTROYED
  self._deaf = voice.deaf or false
  self._mute = voice.mute or false
  self._functions = Functions()
  if (self._node.driver.playerFunctions.size ~= 0) then
    for _, value in pairs(self._node.driver.playerFunctions:full()) do
      self._functions:set(value[1], value[2])
    end
  end
  if (voice.options.volume and voice.options.volume ~= self._volume) then
    self._volume = voice.options.volume
  end
end

function get:lunalink()
  return self._lunalink
end

function get:node()
  return self._node
end

function get:guildId()
  return self._guildId
end

function get:voiceId()
  return self._voiceId
end

function get:textId()
  return self._textId
end

function get:queue()
  return self._queue
end

function get:data()
  return self._data
end

function get:paused()
  return self._paused
end

function get:position()
  return self._position
end

function get:volume()
  return self._volume
end

function get:playing()
  return self._playing
end

function get:loop()
  return self._loop
end

function get:state()
  return self._state
end

function get:deaf()
  return self._deaf
end

function get:mute()
  return self._mute
end

function get:track()
  return self._track
end

function get:functions()
  return self._functions
end

function get:shardId()
  return self._shardId
end

function get:filter()
  return self._filter
end

function get:voice()
  return self._voice
end

---Sends server update to lavalink
---@return nil
function Player:sendServerUpdate()
  local playerUpdate = {
    guildId = self._guildId,
    playerOptions = {
      voice = {
        token = self._voice.serverUpdate.token,
        endpoint = self._voice.serverUpdate.endpoint,
        sessionId = self._voice.sessionId,
      },
    },
  }
  self._node.rest:updatePlayer(playerUpdate)
end

---Destroy the player
---@return nil
function Player:destroy()
  self:checkDestroyed()
  self._sudoDestroy = true
  if self._playing then
    self._node.rest:updatePlayer({
      guildId = self._guildId,
      playerOptions = {
        track = {
          encoded = NULL,
          length = 0,
        },
      },
    })
  end
  self:clean(false)
  self:disconnect()
  self._node.rest:destroyPlayer(self._guildId)
  self._lunalink.players:delete(self._guildId)
  self._state = PlayerState.DESTROYED
  self:debug('Player destroyed')
  self._voiceId = ''
  self._lunalink:emit(Events.PlayerDestroy, self)
  self._sudoDestroy = false
end

---Play a track
---@param track Track | nil
---@param options PlayOptions | nil
---@return Player
function Player:play(track, options)
  options = options or {}

  self:checkDestroyed()

  if track and track.__name ~= 'LunalinkTrack' then
    p(track.__name)
    error('track must be a LunalinkTrack')
  end

  if not track and self._queue.totalSize == 0 then
    error('No track is available to play')
  end

  if not options or type(options.replaceCurrent)  ~= "boolean" then
    local additional = {
      replaceCurrent = false
    }
    for k, v in pairs(additional) do
      options[k] = v
    end
  end

  if track then
    if not options.replaceCurrent and self._queue.current then
      table.insert(self._queue._list, self._queue.current, 1)
    end
    self._queue._current = track
  elseif not self._queue.current then
    self._queue._current = self._queue:_shift(self._queue._list)
  end

  assert(self._queue._current, 'No track is available to play')

  local current = self._queue.current

  local resolveResult = current:resolver(self)

  if not resolveResult or (resolveResult and not resolveResult.isPlayable) then
    self._lunalink:emit(Events.TrackResolveError, self, current)
    self:debug("Player resolve error!")
    self._queue._current = nil
    if self._queue._size ~= 0 then
      self:play()
    else self._lunalink:emit(Events.QueueEmpty, self, self._queue) end
    return self
  end

  self._playing = true
  self._track = current.encoded


  local additional = {
    track = {
      encoded = current.encoded,
      length = current.duration,
    },
    volume = self._volume,
  }

  for k, v in pairs(additional) do
    options[k] = v
  end

  if (options.paused) then
    self._paused = options.paused
    self._playing = not self._paused
  end

  if options.position then self._position = options.position end

  self._node.rest:updatePlayer({
    guildId = self._guildId,
    noReplace = options.noReplace or false,
    playerOptions = options,
  })

  return self
end

---Disconnect from the voice channel
---@return Player
function Player:disconnect()
  self:checkDestroyed()
  if self._voice.state == VoiceConnectState.DISCONNECTED then return self end
  self._voiceId = nil
  self._deaf = false
  self._mute = false
  self._voice:disconnect()
  self:pause()
  self._state = PlayerState.DISCONNECTED
  self:debug('Player disconnected')
  return self
end

---Set the loop mode of the track
---@param mode '[LoopMode](Enumerations.md#loopmode)'
---@return Player
function Player:setLoop(mode)
  self:checkDestroyed()
  self._loop = mode
  return self
end

---Search track directly from player
---@param query string
---@param options SearchOptions
---@return SearchResult
function Player:search(query, options)
  options = options or {}
  local additional = {
    nodeName = self._node.options.name
  }
  for _,v in ipairs(additional) do
    table.insert(options, v)
  end
  return self._lunalink:search(query, options)
end

---Pause the track
---@return Player
function Player:pause()
  self:checkDestroyed()
  if self._paused == true then return self end
  self._node.rest:updatePlayer({
    guildId = self._guildId,
    playerOptions = {
      paused = true,
    },
  })
  self._paused = true
  self._playing = false
  self._lunalink:emit(Events.PlayerPause, self, self._queue.current)
  return self
end

---Resume the track
---@return Player
function Player:resume()
  self:checkDestroyed()
  if self._paused == false then return self end
  self._node.rest:updatePlayer({
    guildId = self._guildId,
    playerOptions = {
      paused = false,
    },
  })
  self._paused = false
  self._playing = true
  self._lunalink:emit(Events.PlayerResume, self, self._queue.current)
  return self
end


function Player:setPause(mode)
  self:checkDestroyed()
  if self._paused == mode then return self end
  self._node.rest:updatePlayer({
    guildId = self._guildId,
    playerOptions = {
      paused = mode,
    },
  })
  self._paused = mode
  self._playing = not mode
  self._lunalink:emit(mode and Events.PlayerPause or Events.PlayerResume, self, self._queue.current)
  return self
end

---Play the previous track
---@return Player
function Player:previous()
  self:checkDestroyed()
  local prevoiusData = self._queue.previous
  local current = self._queue.current
  local index = prevoiusData.length
  if index == 0 and not current then return self end
  self:play(prevoiusData[index])
  self._queue.previous:_splice(index, 1)
  return self
end

---Skip the current track
---@return Player
function Player:skip()
  self:checkDestroyed()
  self._node.rest:updatePlayer({
    guildId = self._guildId,
    playerOptions = {
      track = {
        encoded = NULL,
      },
    },
  })
  return self
end

---Seek to another position in track
---@param position number
---@return Player
function Player:seek(position)
  self:checkDestroyed()
  assert(self._queue.current, 'Player has no current track in it\'s queue')
  assert(self._queue.current.isSeekable, 'The current track isn\'t seekable')

  position = tonumber(position) or 0

  assert(type(position) == "number", 'position must be a number')

  if position < 0 or position > (self._queue.current.duration or 0) then
    position = math.max(math.min(position, self._queue.current.duration or 0), 0)
  end

  self._node.rest:updatePlayer({
    guildId = self._guildId,
    playerOptions = {
      position = position,
    },
  })
  self._queue.current._position = position
  return self
end

---Set another volume in player
---@param volume number
---@return Player
function Player:setVolume(volume)
  self:checkDestroyed()
  assert(type(volume) == "number", 'volume must be a number')
  self._node.rest:updatePlayer({
    guildId = self._guildId,
    playerOptions = {
      volume = volume,
    },
  })
  self._volume = volume
  return self
end

---Set player to mute or unmute
---@param enable boolean
---@return Player
function Player:setMute(enable)
	self:checkDestroyed()
	if enable == self._mute then return self end
	self._mute = enable
	self._voice._mute = self._mute
	self._voice:sendVoiceUpdate()
	return self
end

---Stop all avtivities and reset to default
---@param destroy boolean
---@return Player
function Player:stop(destroy)
	self:checkDestroyed()
	if (destroy) then
		self:destroy()
		return self
  end

	self:clean(false)
  self._node.rest:updatePlayer({
		guildId = self._guildId,
		playerOptions = {
			track = {
				encoded = NULL,
			},
		},
	})

	self._manager:emit(Events.TrackEnd, self, self._queue.current)
  self._manager:emit(Events.PlayerStop, self)

	return self
end

---Set player to deaf or undeaf
---@param enable boolean
---@return Player
function Player:setDeaf(enable)
	self:checkDestroyed()
	if enable == self._deaf then return self end
	self._deaf = enable
	self._voice._deaf = self._deaf
	self._voice:sendVoiceUpdate()
	return self
end

---Reset all data to default
---@param emitEmpty boolean
---@return nil
function Player:clean(emitEmpty)
  self._loop = LoopMode.NONE
  self._queue:clear()
  self._queue._current = nil
  self._queue._previous = {}
  self._volume = self._lunalink.options.config.defaultVolume or 100
  self._paused = true
  self._playing = false
  self._track = nil
  self._data:clear()
  self._position = 0
  if emitEmpty then self._lunalink:emit(Events.QueueEmpty, self, self._queue) end
end

---Set text channel
---@param textId string
---@return Player
function Player:setTextChannel(textId)
  self:checkDestroyed()
  self._textId = textId
  return self
end

---Set voice channel and move the player to the voice channel
---@param voiceId string
---@return Player
function Player:setVoiceChannel(voiceId)
  self:checkDestroyed()
  self:disconnect()
  self._voiceId = voiceId
  self._voice._voiceId = voiceId
  self._voice:connect()
  self._voice:debug('Player moved to voice channel $s', voiceId)
  return self
end

---Send custom player update data to lavalink server
---@param data UpdatePlayerInfo
---@return Player
function Player:send(data)
  self:checkDestroyed()
  self._node.rest:updatePlayer(data)
  return self
end

function Player:checkDestroyed()
  assert(self._state ~= PlayerState.DESTROYED, 'Player is destroyed')
end

function Player:debug(logs, ...)
	local pre_res = string.format(logs, ...)
	local res = string.format(
    '[Lunalink] / [Player @ %s] | %s',
    self._guildId,
    pre_res
  )
	self._lunalink:emit(Events.Debug, res)
end


return Player