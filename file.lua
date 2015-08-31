exports.name = 'bjornbytes/rx'
exports.version = '0.0.1'
exports.license = 'MIT'
exports.dependencies = {
  'luvit/timer'
}

local timer = require 'timer'
local rx = require './rx'

for k, v in pairs(rx) do
  exports[k] = v
end
