local class = require('class')
local json = require('json')
local const = require('const')
local Events = const.Events
local enums = require('enums')

local PlayerState = enums.PlayerState
local LoopMode = enums.LoopMode
local LavalinkPlayerEventsEnum = enums.LavalinkPlayerEventsEnum
local LavalinkEventsEnum = enums.LavalinkEventsEnum

local PlayerEvents = class('PlayerEvents')

function PlayerEvents:__init(lunalink)
  self._lunalink = lunalink
end

function PlayerEvents:initial(data)
  if data.op == LavalinkEventsEnum.PlayerUpdate then
    return self:PlayerUpdate(data)
  end
  local func = self[data.type]
  if func then func(self, data) end
end

function PlayerEvents:TrackStartEvent(data)
  local player = self._lunalink._players:get(data.guildId)
  if not player then return end

  player._playing = true
  player._paused = false
  self._lunalink:emit(Events.TrackStart, player, player._queue._current)
  self:debug(data.guildId, 'Start', json.encode(data))
end

function PlayerEvents:TrackEndEvent(data)
  local player = self._lunalink._players:get(data.guildId)
  if not player then return end

  -- This event emits STOPPED reason when destroying, so return to prevent double emit
  if player._state == PlayerState.DESTROYED then
    return self:debug(data.guildId, 'End', 'Player %s destroyed from end event', player._guildId)
  end

  self:debug(data.guildId, 'End', 'Tracks: %s ' .. json.encode(data), player._queue.size)

  player._playing = false
  player._paused = true

  if data.reason == 'replaced' then
    return self._lunalink:emit(Events.TrackEnd, player, player._queue._current)
  end

  if self:_includes({ 'loadFailed', 'cleanup' }, data.reason) then
    if player._queue._current then
      table.insert(player._queue._previous, player._queue._current)
    end
    if player._queue.size == 0 and player._sudoDestroy then
      return self._lunalink:emit(Events.QueueEmpty, player, player._queue)
    end
    self._lunalink:emit(Events.QueueEmpty, player, player._queue)
    player._queue._current = nil
    return player:play()
  end

  if player.loop == LoopMode.SONG and player.queue.current then
    table.insert(player._queue._list, 1, player._queue._current)
  end

  if player.loop == LoopMode.QUEUE and player.queue.current then
    table.insert(player._queue._list, player._queue._current)
  end

  if player._queue._current then
    table.insert(player._queue._previous, player._queue._current)
  end

  local currentSong = player._queue._current
  player._queue._current = nil

  if player.queue.size ~= 0 then
    self._lunalink:emit(Events.TrackEnd, player, currentSong)
  elseif player._queue.size == 0 and not player._sudoDestroy then
    return self._lunalink:emit(Events.QueueEmpty, player, player.queue)
  else return end

  return player:play()
end

function PlayerEvents:TrackExceptionEvent(data)
  local player = self._lunalink._players:get(data.guildId)
  if not player then return end

  player._playing = false
  player._paused = true
  self._lunalink:emit(Events.PlayerException, player, data)
  self:debug(data.guildId, 'Exception', json.encode(data))
end

function PlayerEvents:TrackStuckEvent(data)
  local player = self._lunalink._players:get(data.guildId)
  if not player then return end

  player._playing = false
  player._paused = true
  self._lunalink:emit(Events.TrackStuck, player, data)
  self:debug(data.guildId, 'Stuck', json.encode(data))
end

function PlayerEvents:WebSocketClosedEvent(data)
  local player = self._lunalink._players:get(data.guildId)
  if not player then return end

  player._playing = false
  player._paused = true
  self._lunalink:emit(Events.PlayerWebsocketClosed, player, data)
  self:debug(data.guildId, 'WebsocketClosed', json.encode(data))
end

function PlayerEvents:PlayerUpdate(data)
  local player = self._lunalink._players:get(data.guildId)
  if not player then return end

  player._position = data.state.position
  self:debug(data.guildId, 'Updated', json.encode(data))
  self._lunalink:emit(Events.PlayerUpdate, player, data)
end

function PlayerEvents:debug(guildId, tag, logs, ...)
  local pre_res = string.format(logs, ...)
	local res = string.format('[Lunalink] / [Player @ %s] / [Events] / [%s] | %s', guildId, tag, pre_res)
	self._lunalink:emit(Events.Debug, res)
end

function PlayerEvents:_includes(t, e)
  for _, value in pairs(t) do
		if value == e then
			return e
		end
	end
	return nil
end

return PlayerEvents