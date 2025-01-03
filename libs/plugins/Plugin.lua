local class = require('class')

local Plugin, get = class('Plugin')

---The interface class for another rainlink plugin, extend it to use
---@class Plugin
---@field isLunalinkPlugin boolean Is a lunalink plugin or not

function Plugin:__init() end

function get:isLunalinkPlugin()
  return true
end

---Name function for getting plugin name
---@return nil
function Plugin:name()
  error('Plugin must implement name() and return a plguin name string')
end

---Type function for diferent type of plugin
---@return nil
function Plugin:type()
  error('Plugin must implement type() and return "sourceResolver" or "default"')
end

---Load function for make the plugin working
---@return nil
function Plugin:load()
  error('Plugin must implement load()')
end

---unload function for make the plugin stop working
---@return nil
function Plugin:unload()
  error('Plugin must implement unload()')
end

return Plugin