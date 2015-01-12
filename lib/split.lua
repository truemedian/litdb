local Transform = require('stream_transform').Transform

local Split = Transform:extend()
function Split:initialize(options)
  options = options or {}

  Transform.initialize(self, options)

  self.buff = ''
  self.sep = options.separator or '\n'
  self.bufferSize = options.bufferSize
  self.falted = false

  -- By default Split stream emits chunks directly. User can provide a mapper
  -- function that serves a purpose similar to a Transform stream. If the
  -- mapper emits objects rather than strings, options.objectMode needs to be
  -- set true.
  self.mapper = options.mapper or function(data) return data end
end

function Split:_transform(data, encoding, callback)
  if self.bufferSize and self.bufferSize < #self.buff + #data then
    self:emit('error', 'Split buffer overflow')
    self.falted = true
  end
  if self.falted then
    callback()
    return
  end
  self.buff = self.buff .. data
  local p = self.buff:find(self.sep)
  while p do
    local to_push = self.mapper(self.buff:sub(1, p - 1))
    if to_push then
      self:push(to_push)
    end
    self.buff = self.buff:sub(p + #self.sep, -1)
    p = self.buff:find(self.sep)
  end
  callback()
end

return Split
