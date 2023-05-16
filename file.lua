  --[[lit-meta
    name = "lil-evil/table-watcher"
    version = "1.0.2"
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
    package = {version = "1.0.2"}
}

--forward declaration
local watcher_metatable

-- no key overwrite
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
        --filter get
        if type(t[watcher_events].fget) == "function" then
            local state, ret = t[watcher_events].fget(t[watcher_data], k)
            if state then return ret end
        end
        --get callback
        if type(t[watcher_events].get) == "function" then
            t[watcher_events].get(t[watcher_data], k)
        end
        if type(t[watcher_data][k]) == "table" then
            return setmetatable({[watcher_data] = t[watcher_data][k], [watcher_events] = t[watcher_events], [watcher_origin] = t[watcher_data]}, watcher_metatable)
        else return t[watcher_data][k] end
    end,
    __newindex = function(t, k, v)
        -- filter set
        if type(t[watcher_events].fset) == "function" then
            local set = t[watcher_events].fset(t[watcher_data], k, v)
            if set == false then return end
        end
        t[watcher_data][k] = v -- set
        -- set callback
        if type(t[watcher_events].set) == "function" then
            t[watcher_events].set(t[watcher_data], k, v)
        end
    end,
    __len = function(t)
        return #t[watcher_data]
    end,
    __pairs = function(t)
        return next, t[watcher_data], nil
    end
}

--- Watch a table for gets and sets
---@param data table table to watch
---@param events table list of event to interact with
---@param events.get function (self, key) trigger when accessing field.
---@param events.set function (self, key, value) trigger when seting field.
---@param events.fget function (self, key)->boolean,any same as get. When returning true,any the property returned is any. exemple (true, "hello") watched.prop == "hello"
---@param events.fset function (self, key, value)->boolean same a set. When returning false, block the set of the field
---@return table
function watcher.watch(data, events)
    if type(data) ~= "table" then error("Missing or invalid table to watch (got "..type(data)..")") end
    if data[watcher_data] then error("This table is already watched") end


    events = type(events) == "table" and events or {}

    return setmetatable({[watcher_data] = data, [watcher_events] = events}, watcher_metatable)

end

--- return a table that no longer trigger events
---@param data table table to unwatch
---@param clone boolean|nil wheither to deep clone the table before return it
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

--- complety destroy all watcher instances of this table and return a shallow copy of original table
---@param data table watcher to detroy
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

--- check if the data is watched
---@param data table
---@return boolean
function watcher.is_watched(data)
    return type(data[watcher_data]) == "table"
end

return watcher