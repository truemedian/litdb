--[[lit-meta
    name = "Richy-Z/clock"
    version = "0.1.0"
    dependencies = {}
    description = "A simple library to get precise UNIX time and other utility functions"
    tags = { "clock", "time", "unix", "ISO", "timestamp", "ffi" }
    license = "Apache 2.0"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

local clock = {}

local ffi = require("ffi")

ffi.cdef [[
      typedef long time_t;

      struct timespec {
          time_t tv_sec;
          long tv_nsec;   // nanoseconds
      };

      int clock_gettime(int clk_id, struct timespec *tp);

      // clock id constants
      enum {
          CLOCK_REALTIME = 0
      };
  ]]

function clock.epoch()
    local timespec = ffi.new("struct timespec")
    local CLOCK_REALTIME = ffi.C.CLOCK_REALTIME

    if ffi.C.clock_gettime(CLOCK_REALTIME, timespec) ~= 0 then
        return 0
    end

    -- calculate time in sec with fractional milliseconds
    return tonumber(timespec.tv_sec) + tonumber(timespec.tv_nsec) / 1e9
end

-- TODO: maybe use our own epoch function for nanoseconds in this ISO?
function clock.ISO()
    local date = os.date("!*t")
    return string.format("%04d-%02d-%02dT%02d:%02d:%02d.000Z",
        date.year, date.month, date.day, date.hour, date.min, date.sec)
end

return clock
