local Transform = require('stream').Transform


local function gsplit2(s, sep)
  local lasti, done, g = 1, false, s:gmatch('(.-)'..sep..'()')
  return function()
    if done then return end
    local v,i = g()
    if s == '' or sep == '' then done = true return s end
    if v == nil then done = true return -1, s:sub(lasti) end
    lasti = i
    return v
  end
end

local Split = Transform:extend()
function Split:initialize(options)
  options = options or {}
  Transform.initialize(self, options)

  self.sep = options.separator or '\n'
  self.buffer = ''
  self.bufferSize = options.bufferSize

  -- By default Split stream emits chunks directly. User can provide a mapper
  -- function that serves a purpose similar to a Transform stream. If the
  -- mapper emits objects rather than strings, options.objectMode needs to be
  -- set true.
  self.mapper = options.mapper or function(data) return data end
end

function Split:_transform(data, callback)
  if self.buffer then
    data = self.buffer .. data
  end
  for line, last in gsplit2(data, '[' .. self.sep .. ']') do
    if type(line) == 'number' then
      self.buffer = last
    else
      local mapped = self.mapper(line)
      if mapped then self:push(mapped) end
    end
  end
  process.nextTick(callback)
end

return Split
