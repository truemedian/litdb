local class = require('class')

---A key-based temporary database system that handles temporary data.
---@class Cache
---<!tag:interface>

local Cache = class('Cache')

---Initial function foc Cache
function Cache:__init()
  self._cache = {}
end

---Set a new data with keys
---@param key string
---@param value unknown
function Cache:set(key, value)
  self._cache[key] = value
  return value
end

---Get existed data using keys, returns nil when not existed
---@param key string
---@return unknown
function Cache:get(key)
  return self._cache[key]
end

---Delete specific key
---@param key string
---@return nil
function Cache:delete(key)
  self._cache[key] = nil
end

---Clear all database data
---@return nil
function Cache:clear()
  self._cache = {}
end

---get the sizes of the database
---@return number
function Cache:size()
  local count = 0
  for _, _ in pairs(self._cache) do
    count = count + 1
  end
  return count
end

---A function to execute for each element in the array.
---Its return value is discarded.
---The function is called with the following arguments:
--- - `value` - the current data
--- - `key` - the current key
---@param callback function
---@return nil
function Cache:for_each(callback)
  for key, value in pairs(self._cache) do
    callback(value, key)
  end
end

---List all cache values
---@return table
function Cache:values()
  local final_res = {}
  for _, value in pairs(self._cache) do
    table.insert(final_res, value)
  end
  return final_res
end

---List all cache values and keys 
---@return table
function Cache:full()
  local final_res = {}
  for key, value in pairs(self._cache) do
    table.insert(final_res, { key, value })
  end
  return final_res
end

return Cache