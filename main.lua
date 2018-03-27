local uv = require 'uv'
local ffi = require 'ffi'
local stdout = require('pretty-print').stdout
local stderr = require('pretty-print').stderr
local stdin = require('pretty-print').stdin
local cbor = require 'cbor'

-- default lua strings to utf8 strings in cbor encoding
cbor.type_encoders.string = cbor.type_encoders.utf8string

local concat = table.concat
local bit = require 'bit'
local rshift = bit.rshift
local band = bit.band
local char = string.char

local handle = uv.new_udp()
handle:bind('127.0.0.1', 0)
-- p(handle:getsockname())

local function send(message)
  local data = cbor.encode(message)
  local dest = 6000
  -- p("Sending", {dest=dest,len=#data})
  handle:send(concat {
    char(rshift(dest, 8)),
    char(band(dest, 0xff)),
    data
  }, '127.0.0.1', 5000)
end


ffi.cdef[[
  void exit(int status);
]]

local handlers = {
  ['s-pid'] = function (pid)
    p('Remote bash process created:', {pid=pid})
  end,
  ['s-out'] = function (data)
    stdout:write(data)
  end,
  ['s-err'] = function (data)
    stderr:write(data)
  end,
  ['s-exit'] = function (code, signal)
    stdin:set_mode(0)
    print()
    p("Remote bash process exited:", {code=code,signal=signal})
    ffi.C.exit(signal or code)
  end,
}

handle:recv_start(function (err, data)
  assert(not err, err)
  if not data then return end
  -- p(err, data)
  local message = cbor.decode(data)
  handlers[message[1]](unpack(message, 2))
end)

stdin:read_start(function (err, data)
  assert(not err, err)
  send {
    's-in', data
  }
end)

stdin:set_mode(1)

send {
  'spawn',
  'bash',
  {
    args = { '-l' },
    pty = true,
    detached = true
  }
}
-- local cols, rows = stdin:get_winsize()
-- send { 's-resize', cols, rows }

uv.run()
