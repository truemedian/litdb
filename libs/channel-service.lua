local uv = require 'uv'
local cbor = require 'cbor'
-- default lua strings to utf8 strings in cbor encoding
cbor.type_encoders.string = cbor.type_encoders.utf8string

return function (Service, port)

  local server = uv.new_udp()
  assert(server:bind('127.0.0.1', port))

  local channels = {}
  local function get_channel(id, addr)
    local channel = channels[id]
    if not channel then
      channel = setmetatable({ id = id }, { __index = Service })
      function channel:send(...)
        -- p('->', { id, ... })
        local message = cbor.encode { id, ... }
        server:send(message, self.ip, self.port)
      end
      channels[id] = channel
    end
    channel.ip = addr.ip
    channel.port = addr.port
    return channel
  end

  server:recv_start(function (err, data, addr)
    if err then return print(err) end
    if not data then return end
    local channel
    local success, error = xpcall(function ()
      local message = cbor.decode(data)
      -- p('<-', message)
      assert(type(message) == 'table' and #message >= 1, 'Message must be list')
      local id = table.remove(message, 1)
      channel = get_channel(id, addr)
      local fn = Service[table.remove(message, 1)]
      assert(type(fn) == 'function', 'Invalid command')
      fn(channel, unpack(message))
    end, debug.traceback)
    if not success then
      print(error)
      if channel then
        channel:send('error', error)
      end
    end
  end)

  p('UDP server bound', server:getsockname())

end
