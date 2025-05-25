--[[lit-meta
    name = "Richy-Z/clock"
    version = "0.2.1"
    dependencies = {}
    description = "A simple library to get precise UNIX time and other utility functions"
    tags = { "clock", "time", "unix", "iso8601", "timestamp", "ffi", "milliseconds" }
    license = "Apache 2.0"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

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

local function epoch()
    local timespec = ffi.new("struct timespec")
    local CLOCK_REALTIME = ffi.C.CLOCK_REALTIME

    if ffi.C.clock_gettime(CLOCK_REALTIME, timespec) ~= 0 then
        return 0
    end

    -- calculate time in sec with fractional milliseconds
    return tonumber(timespec.tv_sec) + tonumber(timespec.tv_nsec) / 1e9
end

local function milliseconds()
    return epoch() * 1000
end

local function iso8601()
    local now = epoch()
    local seconds = math.floor(now)
    local millis = math.floor((now - seconds) * 1000)

    local date = os.date("!*t", seconds)
    return string.format("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
        date.year, date.month, date.day, date.hour, date.min, date.sec, millis)
end

local function iso8601_parse(str)
    local year, month, day, hour, min, sec, millis = str:match(
        "(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)%.(%d+)Z"
    )

    if not year then -- fallback without milliseconds
        year, month, day, hour, min, sec = str:match(
            "(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z"
        )
        millis = 0
    end

    if not year then
        return nil, "Invalid ISO 8601 format"
    end

    local t = {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
        isdst = false, -- avoids daylight saving time offset errors etc
    }

    -- force UTC interpretation
    -- forgetting to implement UTC support was a costly mistake..
    local localtime = os.time(t)
    local offset = os.difftime(os.time(os.date("!*t", localtime)), localtime) ---@diagnostic disable-line: param-type-mismatch
    local utcTime = localtime + offset

    return utcTime + tonumber(millis) / 1000
end

-- tests
assert(math.floor(iso8601_parse("2025-05-27T23:45:12.123Z")) == 1748389512) ---@diagnostic disable-line: param-type-mismatch
-- p(iso8601_parse("2025-05-27T23:45:12.123Z"))

p(iso8601_parse("2025-05-27T23:45:12.123Z"))

return {
    epoch = epoch,
    now = epoch, -- alias for epoch

    milliseconds = milliseconds,

    iso8601 = iso8601,
    iso8601_parse = iso8601_parse
}
