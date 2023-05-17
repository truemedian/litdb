  --[[lit-meta
    name = "lil-evil/table-watcher"
    version = "1.0.3"
    dependencies = {}
    description = "An event based table watcher"
    tags = { "table", "watcher", "observe", "event" }
    license = "MIT"
    author = { name = "lilevil"}
    homepage = "https://github.com/lil-evil/table-watcher"
  ]]


---@diagnostic disable: undefined-doc-param
---@module table-watcher

local watcher = {
    package = {version = "1.0.3"}
}

--forward declaration
local watcher_metatable

-- no key overwrite or ugly __my__not__so__hiden__property__
-- let user full choice of keys, with no overwriting problems
local watcher_data, watcher_origin, watcher_events = {}, {}, {}

-- https://gist.github.com/tylerneylon/81333721109155b2d244
local function deep_clone(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
  
    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[deep_clone(k, s)] = deep_clone(v, s) end
    return res
end

watcher_metatable = {
    __index = function(t, k)
        --get callback
        if type(t[watcher_events].get) == "function" then
            local block, val = t[watcher_events].get(t[watcher_data], k, t[watcher_events])
            if block == t[watcher_events].block then return val end
        end
        if type(t[watcher_data][k]) == "table" then
            return setmetatable({[watcher_data] = t[watcher_data][k], [watcher_events] = t[watcher_events], [watcher_origin] = t[watcher_data]}, watcher_metatable)
        else return t[watcher_data][k] end
    end,
    __newindex = function(t, k, v)
        -- set callback
        if type(t[watcher_events].set) == "function" then
            local block = t[watcher_events].set(t[watcher_data], k, v, t[watcher_events])
            if block == t[watcher_events].block then return end
        end
        t[watcher_data][k] = v -- set
    end,
    __len = function(t)
        return #t[watcher_data]
    end,
    __pairs = function(t)
        return next, t[watcher_data], nil
    end
}

--- Watch a table for gets and sets
---@param data table Table to watch
---@param events table List of event to interact with
---@param events.get function (self, key, self) Triggered when accessing field.
---@param events.set function (self, key, value, self) Triggered when seting field.
---@return table
function watcher.watch(data, events)
    if type(data) ~= "table" then error("Missing or invalid table to watch (got "..type(data)..")") end
    if data[watcher_data] then error("This table is already watched") end


    events = type(events) == "table" and deep_clone(events) or {}

    events.origin = data
    events.block = {}
    function events:ret(value) return self.block, value end

    return setmetatable({[watcher_data] = data, [watcher_events] = events}, watcher_metatable)

end

--- Return a table that no longer trigger events
---@param data table Table to unwatch
---@param clone boolean|nil Wheither to deep clone the table before return it or not
---@return table
function watcher.unwatch(data, clone)
    if type(data) ~= "table" then error("Missing or invalid table to unwatch (got "..type(data)..")") end
    if not data[watcher_data] then error("This table is not watched") end
    
    local data_ = data[watcher_data]
    if clone == true then
        data_ = deep_clone(data_)
    end
    return data_
end

--- Complety destroy all watcher instances of this table and return a shallow copy of original table
---@param data table Watcher to destroy
---@return table
function watcher.destroy(data)
    if type(data) ~= "table" then error("Missing or invalid table to unwatch (got "..type(data)..")") end
    if not data[watcher_data] then error("This table is not watched") end

    setmetatable(data, {})
    for k, v in pairs(data[watcher_data]) do
        data[k] = v
    end
    for i, v in ipairs(data[watcher_data]) do
        data[i] = v
    end
    data[watcher_events] = nil
    data[watcher_origin] = nil
    data[watcher_data] = nil

    return data
end

--- Check if the data is watched
---@param data table
---@return boolean
function watcher.is_watched(data)
    return type(data[watcher_data]) == "table"
end

return watcher