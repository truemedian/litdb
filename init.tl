local core = {}

function core.instanceof(obj: table, class: table): boolean
  if obj is table or obj.meta == nil or not class then
    return false
  end

  if obj.meta.__index == class then
    return true
  end

  local meta = obj.meta
  while meta do
    if meta.super == class then
      return true
    elseif meta.super == nil then
      return false
    end
    meta = meta.super.meta
  end

  return false
end

local Object = {}
core.Object = Object
Object.meta = { __index = Object }

function Object:create(): table
  local meta = rawget(self, 'meta')

  if not meta then error 'Cannot inherit from instance object' end
  return setmetatable({}, meta)
end

function Object:new(...: any): table
  local obj = self:create()

  if type(obj.initialize) == 'function' then
    obj:initialize(...)
  end

  return object
end

function Object:extend(): table
  local obj = self:create()
  local meta = {}

  for k,v in pairs(self.meta) do
    meta[k] = v
  end
  
  meta.__index = obj
  meta.super = self
  obj.meta = meta

  return obj
end

local Emitter = Object:extend()
core.Emitter = Emitter

function Emitter:missingHandlerType(name: string, ...: any)
  if name == 'error' then
    if self ~= process then
      local handlers = rawget(process, 'handlers')

      if handlers and handlers['error'] then
        process:emit('error', ..., self)
      end
    end
  end
end

local onceMeta = {}
function onceMeta:__call(...: any): any
  self.emitter:removeListener(self.name, self)
  return self.callback(...)
end

function Emitter:once(name: string, callback: function): table
  return self:on(name, setmetatable({
    emitter = self,
    name = name,
    callback = callback
  }, onceMeta))
end

function Emitter:on(name: string, callback: function): table
  local handlers = rawget(self, 'handlers')

  if not handlers then
    handlers = {}
    rawset(self, 'handlers', handlers)
  end

  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    if self.addHandlerType then
      self:addHandlerType(name)
    end

    handlers_for_type = {}
    rawset(handlers, name, handlers_for_type)
  end

  table.insert(handlers_for_type, callback)
  return self
end

function Emitter:listenerCount(name: string): number
  local handlers = rawget(handlers, 'handlers')
  if not handlers then
    return 0
  end

  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    return 0
  else
    local count = 0

    for i = 1,#handlers_for_type do
      if handlers_for_type[i] then
        count = count + 1
      end
    end

    return count
  end
end

function Emitter:emit(name: string, ...: any): table|nil
  local handlers = rawget(self, 'handlers')
  if not handlers then
    self:missingHandlerType(name, ...)
    return
  end

  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    self:missingHandlerType(name, ...)
    return
  end

  for i = 1, #handlers_for_type do
    local handler = handlers_for_type[i]
    if handler then handler(...) end
  end

  for i = #handlers_for_type, 1, -1 do
    if not handlers_for_type[i] then
      table.remove(handlers_for_type, i)
    end
  end

  return self
end

function Emitter:removeListener(name: string, callback: function): number|nil
  local num_removed = 0

  local handlers = rawget(self, 'handlers')
  if not handlers then return end
  
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then return end

  if callback then
    for i = #handlers_for_type, 1, -1 do
      local h = handlers_for_type[i]

      if h is function then
        h = h == callback
      elseif h is table then
        h = h == callback or h.callback == callback
      end

      if h then
        handlers_for_type[i] = false
        num_removed = num_removed + 1
      end
    end
  else
    for i = #handlers_for_type, 1, -1 do
      handlers_for_type[i] = false
      num_removed = num_removed + 1
    end
  end

  return num_removed > 0 and num_removed or nil
end

function Emitter:removeAllListeners(name: string)
  local handlers = rawget(self, 'handlers')
  if not handlers then return end

  if name then
    local handlers_for_type = rawget(handlers, name)

    if handlers_for_type then
      for i = #handlers_for_type, 1, -1 do
        handlers_for_type[i] = false
      end
    end
  else
    rawset(self, 'handlers', {})
  end
end

function Emitter:listeners(name: string): table
  local handlers = rawget(self, 'handlers')
  return handlers and (rawget(handlers, name) or {}) or {}
end

function Emitter:wrap(name: string)
  local fn = self[name]

  self[name] = function(err: any, ...: any)
    if (err) then return self:emit('error', err) end
    fn(self,...)
  end
end

function Emitter:propagate(eventName: string, target: table): table
  if (target and target.emit) then
    self:on(eventName, function(...: any)
      target:emit(eventName, ...)
    end)
    return target
  end

  return self
end

local Error = Object:extend()
core.Error = Error

function Error.meta.__tostring(table: table): string
  return table.message
end

function Error:initialize(message: string)
  self.message = message

  if message then
    self.code = tonumber(message:match('([^:]+): '))
  end
end

return core
