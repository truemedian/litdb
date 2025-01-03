local class = require('class')
local json = require('json')
local FilterData = require('const').FilterData
local Events = require('const').Events
local PlayerState = require('enums').PlayerState
local NULL = json.null

---This class is for set, clear and managing filter
---@class AudioFilter
---<!tag:interface>
---@field player Player A player class

local AudioFilter, get = class('AudioFilter')

---Initial function for AudioFilter
---@param player Player
function AudioFilter:__init(player)
  self._current = nil
  self._player = player
end

function get:current()
  return self._current
end

---Create a new player.
---@param filter AudioFilterOptions
---@return Player
function AudioFilter:set(filter)
  self:_checkDestroyed()

  local filter_data = FilterData[filter]

  if not filter_data then
    self:debug("Filter %s not avaliable in Rainlink's filter prebuilt", filter)
    return self._player
  end

  self._player:send({
    guildId = self._player._guildId,
    playerOptions = { filters = filter_data }
  })

  self._current = filter_data

  local log_debug = { '%s filter has been successfully set.', filter }
  if filter == 'clear' then
    log_debug = { 'All filters have been successfully reset to their default positions.', nil }
  end

  self.debug(table.unpack(log_debug))

  return self._player
end

---Clear all filter that avaliable.
---@return Player
function AudioFilter:clear()
  self:_checkDestroyed()

  self._player:send({
    guildId = self._player._guildId,
    playerOptions = { filters = {} }
  })

  self._current = nil

  self.debug('All filters have been successfully reset to their default positions.')

  return self._player
end

---Set filter volume (not global)
---@param volume number
---@return Player
function AudioFilter:setVolume(volume)
  return self:setRaw({ volume = volume })
end

---Set equalizer in filter
---@param equalizer 'Table<{ band = number, gain = number }>'
---@return Player
function AudioFilter:setEqualizer(equalizer)
  return self:setRaw({ equalizer = equalizer })
end

---Set karaoke filter with extended options
---@param karaoke '{ level = number, monoLevel = number, filterBand = number, filterWidth = number }'
---@return Player
function AudioFilter:setKaraoke(karaoke)
  return self:setRaw({ karaoke = karaoke or NULL })
end

---Set timescale options
---@param timescale '{ speed = number, pitch = number, rate = number }'
---@return Player
function AudioFilter:setTimescale(timescale)
  return self:setRaw({ karaoke = timescale or NULL })
end

---Set tremolo options
---@param tremolo '{ frequency = number, depth = number }'
---@return Player
function AudioFilter:setTremolo(tremolo)
  return self:setRaw({ tremolo = tremolo or NULL })
end

---Set vibrato options
---@param vibrato '{ frequency = number, depth = number }'
---@return Player
function AudioFilter:setVibrato(vibrato)
  return self:setRaw({ vibrato = vibrato or NULL })
end

---Set rotation options
---@param rotation '{ rotationHz = number }'
---@return Player
function AudioFilter:setRotation(rotation)
  return self:setRaw({ rotation = rotation or NULL })
end

---Set tremolo options
---@param distortion '[LavalinkDistortion](https://lavalink.dev/api/rest#rotation)'
---@return Player
function AudioFilter:setDistortion(distortion)
  return self:setRaw({ distortion = distortion or NULL })
end

---Set channelMix options
---@param channelMix '{ leftToLeft = number, leftToRight = number, rightToLeft = number, rightToRight = number, }'
---@return Player
function AudioFilter:setChannelMix(channelMix)
  return self:setRaw({ channelMix = channelMix or NULL })
end

---Set lowPass options
---@param lowPass '{ smoothing = number }'
---@return Player
function AudioFilter:setLowPass(lowPass)
  return self:setRaw({ lowPass = lowPass or NULL })
end

function AudioFilter:setRaw(filter)
  self:_checkDestroyed()

  self._player:send({
    guildId = self._player._guildId,
    playerOptions = {
      filters = filter
    }
  })

  self._current = filter

  self.debug('Custom filter has been successfully set. Data: %s', json.encode(filter))

  return self._player
end

function AudioFilter:_checkDestroyed()
  assert(self._player._state ~= PlayerState.DESTROYED, 'Player is destroyed')
end

function AudioFilter:debug(logs, ...)
	local pre_res = string.format(logs, ...)
	local res = string.format(
    '[Lunalink] / [Player @ %s] / [Filter] | %s',
    self._player._guildId,
    pre_res
  )
	self._player._lunalink:emit(Events.Debug, res)
end

return AudioFilter