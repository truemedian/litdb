local class = require('class')
local const = require('const')
local Events = const.Events

---A class for managing track queue
---@class Queue
---<!tag:interface>
---@field player Player A player class
---@field current '[[Track]]/nil' Current playing track
---@field previous 'Table<[[Track]]>' Previous playing tracks
---@field list 'Table<[[Track]]>' Current playing tracks
---@field lunalink Core Manager class
---@field size number Get the size of queue
---@field totalSize number Get the size of queue including current
---@field isEmpty boolean Check if the queue is empty or not
---@field duration number Get the queue's duration

local Queue, get = class('Queue')

---The lunalink track queue handler class
---@param lunalink Core
---@param player Player
function Queue:__init(lunalink, player)
  self._list = {}
  self._previous = {}
  self._current = nil
  self._player = player
  self._lunalink = lunalink
end

function get:current()
  return self._current
end

function get:previous()
  return self._previous
end

function get:player()
  return self._player
end

function get:lunalink()
  return self._lunalink
end

function get:list()
  return self._list
end

function get:size()
  return #self._list
end

function get:totalSize()
  return #self._list + (self._current and 1 or 0)
end

function get:isEmpty()
  return #self._list == 0
end

function get:duration()
  return self:_reduce(self._list, function (acc, cur)
    return acc + (cur.duration or 0)
  end, 0)
end

---Add track(s) to the queue
---@param track Track
---@return Queue
function Queue:add(track)
  assert(track.__name == 'LunalinkTrack', 'Track must be an instance of LunalinkTrack')

  if not self._current then
    self._current = track
    return self
  end

  table.insert(self._list, track)

  self._lunalink:emit(
    Events.QueueAdd,
    self._player,
    self,
    track
  )

  return self
end

---Shuffle the queue
---@return Queue
function Queue:shuffle()
  math.randomseed(os.time())
  for i = #self._list, 2, -1 do
    local j = math.random(i)
    self._list[i], self._list[j] = self._list[j], self._list[i]
  end
  self._lunalink:emit(Events.QueueShuffle, self._player, self)
  return self
end

---Remove track from the queue
---@param position number
---@return Queue
function Queue:remove(position)
  if position < 1 or position >= #self._list then
    error('Position must be between 1 and ' .. #self._list)
  end
  table.remove(self._list, position)
  self._lunalink:emit(Events.QueueRemove, self._player, self)
  return self
end

---Clear the queue
---@return Queue
function Queue:clear()
  self._list = {}
  self._lunalink:emit(Events.QueueClear, self._player, self)
  return self
end

function Queue:_reduce(tbl, func, initial)
	local accumulator = initial
	for _, value in ipairs(tbl) do
		accumulator = func(accumulator, value)
	end
	return accumulator
end

function Queue:_some(tbl, callback)
  for _, value in ipairs(tbl) do
    if callback(value) then
      return true
    end
  end
  return false
end

function Queue:_shift(tbl)
  local first = tbl[1]
  table.remove(tbl, 1)
  return first
end

function Queue:_splice(t, index, count)
  for i = 1, count do
    table.remove(t, index)
  end
end

return Queue