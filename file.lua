--[[lit-meta
  name = "creationix/defer"
  version = "1.0.1"
  homepage = "https://github.com/creationix/luv-defer"
  description = "Simple defer function using the libuv event loop in lua."
  tags = {"luv", "uv", "defer"}
  license = "MIT"
  author = { name = "Tim Caswell" }
]]

local uv = require 'uv'

local dqueue = {}
local function defer(fn)
  dqueue[#dqueue + 1] = fn
end
local function on_check()
  while #dqueue > 0 do
    local success, error = xpcall(table.remove(dqueue, 1), debug.traceback)
    if not success then print('In deferred function:\n' .. error) end
  end
end
local dcheck = uv.new_check()
dcheck:unref()
dcheck:start(on_check)
local dprepare = uv.new_prepare()
dprepare:unref()
dprepare:start(on_check)

return defer
