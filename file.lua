--[[lit-meta
    name = "Richy-Z/clock"
    version = "0.3.0"
    dependencies = {}
    description = "A simple library to get precise UNIX time and other utility functions"
    tags = { "clock", "time", "unix", "iso8601", "timestamp", "ffi", "milliseconds" }
    license = "Apache 2.0"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

local ffi = require("ffi")

local floor = math.floor

local time = os.time
local difftime = os.difftime
local date = os.date

local fmt = string.format

local insert = table.insert
local remove = table.remove
local concat = table.concat

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

---  - Alias: `clock.now()`
---
--- Returns the current UNIX time in seconds with fractional milliseconds using the OS' native time function via FFI.
---
--- ```lua
--- local currentTime = clock.epoch()
---
--- print(currentTime) -- 1748187427.5988
--- ```
---@return integer
local function epoch()
    local timespec = ffi.new("struct timespec")
    local CLOCK_REALTIME = ffi.C.CLOCK_REALTIME

    if ffi.C.clock_gettime(CLOCK_REALTIME, timespec) ~= 0 then
        return 0
    end

    -- calculate time in sec with fractional milliseconds
    return tonumber(timespec.tv_sec) + tonumber(timespec.tv_nsec) / 1e9
end

--- Uses `clock.epoch()` to give you the current UNIX time in milliseconds. It is a simple wrapper that just multiplies the result of `clock.epoch()` by 1000.
---
--- ```lua
--- local currentMillis = clock.milliseconds()
---
--- print(currentMillis) -- 1748187535644
--- ```
---@return integer
local function milliseconds()
    return epoch() * 1000
end

--- Returns the current time or optional `t` in ISO 8601 format (UTC), including milliseconds (e.g., 2025-05-27T23:45:12.123Z).
---
--- ```lua
--- local currentIso = clock.iso8601()
---
--- print(currentIso) -- '2025-05-25T15:40:20.902Z'
--- ```
---@param t? number
---@return string
local function iso8601(t)
    t = t or epoch()

    local seconds = floor(t)
    local millis = floor((t - seconds) * 1000)

    local date = date("!*t", seconds)
    return fmt("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
        date.year, date.month, date.day, date.hour, date.min, date.sec, millis)
end

--- Parses `str`, hopefully an ISO 8601 formatted timestamp, back into a UNIX timestamp in seconds with fractional milliseconds (if present). Assumes UTC and accounts for local timezones automatically.
---
--- ```lua
--- local example = "2025-05-27T23:45:12.123Z"
--- local parsed = clock.iso8601_parse(example)
---
--- print(parsed) -- 1748389512.123
---
--- assert(math.floor(iso8601_parse("2025-05-27T23:45:12.123Z")) == 1748389512)
--- ```
---@param str string
---@return number?
---@return string?
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
    local localtime = time(t)
    local offset = difftime(time(date("!*t", localtime)), localtime) ---@diagnostic disable-line: param-type-mismatch
    local utcTime = localtime + offset

    return utcTime + tonumber(millis) / 1000
end

-- tests
assert(floor(iso8601_parse("2025-05-27T23:45:12.123Z")) == 1748389512) ---@diagnostic disable-line: param-type-mismatch
-- p(iso8601_parse("2025-05-27T23:45:12.123Z"))

local _timeUnits = {
    { name = "year",   seconds = 365 * 24 * 60 * 60 },
    { name = "month",  seconds = 30 * 24 * 60 * 60 },
    { name = "day",    seconds = 24 * 60 * 60 },
    { name = "hour",   seconds = 60 * 60 },
    { name = "minute", seconds = 60 },
    { name = "second", seconds = 1 },
}

--- Returns a "pretty" string where the `seconds` provided are made into an actual sentence.
---
--- Yes, of course it uses the Oxford comma before an "and".
---
--- ```lua
--- local sentence = clock.prettyTime(1000)
---
--- print(sentence) -- "16 minutes, and 40 seconds"
--- ```
---@param seconds number Time in seconds
---@return string
local function prettyTime(seconds)
    local result = {}

    for _, unit in ipairs(_timeUnits) do
        if seconds >= unit.seconds then
            local value = floor(seconds / unit.seconds)
            seconds = seconds % unit.seconds
            insert(result, value .. " " .. unit.name .. (value > 1 and "s" or ""))
        end
    end

    if #result == 0 then
        return "0 seconds"
    elseif #result == 1 then
        return result[1]
    else
        local last = remove(result)
        return concat(result, ", ") .. ", and " .. last
    end
end

return {
    epoch = epoch,
    now = epoch, -- alias for epoch

    milliseconds = milliseconds,

    iso8601 = iso8601,
    iso8601_parse = iso8601_parse,

    prettyTime = prettyTime
}
