--[[lit-meta
  name = "lowscript-lang/lsvm"
  version = "0.1.1"
  dependencies = {}
  description = "Virtual Machine for the LowScript programming language."
  tags = { "vm", "moonscript" }
  license = "MIT"
  author = { name = "Martín Aguilar", email = "ik7swordking@gmail.com" }
  homepage = "https://github.com/lowscript-lang/lsvm"
]]
local VM
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, options)
      if options == nil then
        options = {
          module = false
        }
      end
      self.options = options
      self.env = { }
    end,
    __base = _base_0,
    __name = "VM"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  VM = _class_0
end
return {
  VM = VM
}
