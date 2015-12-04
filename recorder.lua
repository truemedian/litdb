local ffi = require('ffi')
local uv = require('uv')
local wrapStream = require('coro-channel').wrapStream
local wrapRead = require('coro-channel').wrapRead
local split = require('coro-split')
local utils = require('utils')
local stdin = utils.stdin
local stdout = utils.stdout

ffi.cdef[[
  struct winsize {
      unsigned short ws_row;
      unsigned short ws_col;
      unsigned short ws_xpixel;   /* unused */
      unsigned short ws_ypixel;   /* unused */
  };
  int openpty(int *amaster, int *aslave, char *name,
              void *termp,
              const struct winsize *winp);
]]

local master = ffi.new("int[1]")
local slave = ffi.new("int[1]")
local name = ffi.new("char[1024]")
local winp = ffi.new("struct winsize")
winp.ws_row = 24
winp.ws_col = 80

-- Create the pty
ffi.C.openpty(master, slave, name, nil, winp)

-- Convert to lua values, freeing the ffi values.
master, slave, name = master[0], slave[0], ffi.string(name)

p {
  master = master,
  slave = slave,
  name = name
}

local output = {}

print("Spawning bash and piping to pty while recording output")
uv.spawn("/bin/bash", {
  stdio = {slave, slave, slave},
  detached = true,
}, function (...)
  stdin:set_mode(0)
  stdin:read_stop()
  print("Bash exited!")
  p(output)
end)

local pipe = uv.new_pipe(false)
pipe:open(master)

pipe:read_start(function (err, data)
  assert(not err, err)
  if data then
    stdout:write(data)
    output[#output + 1] = data
  end
end)
stdin:set_mode(1)
stdin:read_start(function (err, data)
  assert(not err, err)
  pipe:write(data)
end)

uv.run()
uv.tty_reset_mode()
