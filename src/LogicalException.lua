----
 -- node-exceptions
 --
 -- (c) 'Damilare Darmie Akinlaja <darmie@riot.ng>
 --
 -- For the full copyright and license information, please view the LICENSE
 -- file that was distributed with this source code.
--

local LogicalException
do
  local _class_0
  local _parent_0 = debug
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, message, status, code)
      debug.traceback()
      self.name = self.__name
      if code then
        self.message = tostring(code) .. ": " .. tostring(message)
      else
        self.message = message
      end
      self.status = status or 500
      self.code = code
    end,
    __base = _base_0,
    __name = "LogicalException",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  LogicalException = _class_0
end
exports.LogicalException = LogicalException
