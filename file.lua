--[[lit-meta
  name = "ravener/stopwatch"
  version = "0.0.1"
  dependencies = {}
  description = "A simple stopwatch for Luvit"
  tags = { "stopwatch", "time", "timer" }
  license = "MIT"
  author = { name = "Ravener", email = "ravener.anime@gmail.com" }
  homepage = "https://github.com/ravener/lit-stopwatch"
]]
local uv = require("uv")

local hrtime = uv.hrtime
local floor = math.floor

local Stopwatch = {}
local get = {}

local function round(n, i)
  local m = 10 ^ (i or 0)
  return floor(n * m + 0.5) / m
end

function Stopwatch:__index(k)
  if get[k] then
    return get[k](self)
  end

  return Stopwatch[k]
end

function Stopwatch:__tostring()
  local duration = self.duration

  if duration > 1000 then
    return string.format("%ss", round(duration / 1000, self.digits))
  end

  if duration > 1 then
    return string.format("%sms", round(duration, self.digits))
  end

  return string.format("%sμs", round(duration * 1000, self.digits))
end

function Stopwatch:stop()
  if self.running then
    self._end = hrtime()
  end
end

function Stopwatch:restart()
  self._start = hrtime()
  self._end = nil
end

function Stopwatch:reset()
  self._start = hrtime()
  self._end = self._start
end

function Stopwatch:start()
  if not self.running then
    self._start = self._start + hrtime() - self._end
    self._end = nil
  end
end

function get.running(self)
  return not self._end
end

function get.duration(self)
  local ns = (self._end or hrtime()) - self._start
  return ns / 1000000
end

local function new(digits)
  local self = {}

  self.digits = digits or 2
  self._start = hrtime()

  return setmetatable(self, Stopwatch)
end

return new
