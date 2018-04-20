--[[lit-meta
  name = "kubos/cbor-message-protocol"
  version = "0.0.1"
  description = "Simple protocol for streaming CBOR messages with backpressure over UDP"
  tags = { "kubos", "udp", "cbor", "backpressure"}
  author = { name = "Tim Caswell", email = "tim@kubos.co" }
  homepage = "https://github.com/kubos/kubos"
  dependencies = {
    "creationix/cbor",
    "creationix/defer",
  }
]]

local cbor = require 'cbor'
local defer = require 'defer'
local byte = string.byte

return function (handle, on_message, log_messages)
  local paused = false
  local write_queue = {}

  local function resume()
    if not paused then return end
    paused = false
    while not paused and #write_queue > 0 do
      local co = table.remove(write_queue, 1)
      local success, result = xpcall(function ()
        return coroutine.resume(co)
      end, debug.traceback)
      if not success then
        print(result)
      end
    end
  end

  local function send_message(message, ...)
    if paused then
      write_queue[write_queue + 1] = coroutine.running()
      coroutine.yield()
    end
    if log_messages then p('->', message) end
    return handle:send('\x00' .. cbor.encode(message), ...)
  end

  local function send_pause(...)
    if log_messages then p '-> pause' end
    return handle:send('\x01', ...)
  end

  local function send_resume(...)
    if log_messages then p '-> resume' end
    return handle:send('\x02', ...)
  end

  handle:recv_start(function (err, data, addr)
    if err then return print(err) end
    if not data then return end
    local control = byte(data, 1)
    if control == 1 then
      if log_messages then p '<- pause' end
      paused = true
      return
    elseif control == 2 then
      if log_messages then p '<- resume' end
      return defer(resume)
    elseif control ~= 0 then
      return print("Ignoring unknown control frame: " .. control)
    end
    local message = cbor.decode(data, 2)
    if log_messages then p('<-', message) end
    return on_message(message, addr)
  end)

  return send_message, send_pause, send_resume
end
