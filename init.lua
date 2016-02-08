--[[
 * ee-first
 * Copyright(c) 2014 Jonathan Ong
 * MIT Licensed
]]

local push = require('table').insert
local Object = require('core').Object

--[[
 * Create the event listener.
 * @private
]]

local function listener(ee, event, done)
  return function (...)
    local args = { ... }
    local err = (event == 'error') and args[1] or nil

    done(err, ee, event, args)
  end
end

--[[
 * Get the first event in a set of event emitters and event pairs.
 *
 * @param {array} stuff
 * @param {function} done
 * @public
]]

local function first(stuff, done)
  if (stuff == nil or type(stuff) ~= 'table') then
    error('arg must be an array of [EventEmitter, events...] arrays')
  end

  local cleanups = {}

  local function cleanup()
    for i = 1, #cleanups do
      cleanups[i].ee:removeAllListeners()
    end
  end

  local function callback(...)
    cleanup()
    done(...)
  end

  for i = 1, #stuff do
    local arr = stuff[i]

    if (type(arr) ~= 'table' or #arr < 2) then
      error('each array member must be [EventEmitter, events...]')
    end

    local ee = arr[1]

    for j = 2, #arr do
      local event = arr[j]
      local fn = listener(ee, event, callback)

      -- listen to the event
      ee:on(event, fn)
      -- push this listener to the list of cleanups
      push(cleanups, {
        ee = ee,
        event = event,
        fn = fn
      })
    end
  end

  local Thunk = Object:extend()
  function Thunk:done(fn)
    if done == nil then
      done = fn
    end
  end

  function Thunk:cancel()
    cleanup()
  end

  -- the original code returned a thunk...
  return Thunk:new()
end

--[[
 * Module exports.
 * @public
]]

return first