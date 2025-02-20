local class = require('class')
local Cache = require('utils/Cache')

---This class will mainly stores custom function and execute it using `:exec()`
---@class Functions
---<!tag:interface>

local Functions = class('Functions', Cache)

---Initial class for Functions
function Functions:__init(...)
  self._bind_list = { ... }
  Cache.__init(self)
end

---Executor for custom functions
---@param commandName string
---@param ... unknown
---@return unknown
function Functions:exec(commandName, ...)
  local func = self:get(commandName)
  if not func then return nil end
  if self._bind_list then return func(table.unpack(self._bind_list), ...) end
  return func(...)
end

return Functions