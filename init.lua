--[[

Copyright 2015 Dennis Schridde <dennis.schridde@uni-heidelberg.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local ffi = require("ffi")

ffi.cdef[[
struct tm
{
  int tm_sec;                   /* Seconds.     [0-60] (1 leap second) */
  int tm_min;                   /* Minutes.     [0-59] */
  int tm_hour;                  /* Hours.       [0-23] */
  int tm_mday;                  /* Day.         [1-31] */
  int tm_mon;                   /* Month.       [0-11] */
  int tm_year;                  /* Year - 1900.  */
  int tm_wday;                  /* Day of week. [0-6] */
  int tm_yday;                  /* Days in year.[0-365] */
  int tm_isdst;                 /* DST.         [-1/0/1]*/
  long int __tm_gmtoff;         /* Seconds east of UTC.  */
  const char *__tm_zone;        /* Timezone abbreviation.  */
};
int getdate_r(const char *string, struct tm *res);
char *strptime(const char *s, const char *format, struct tm *tm);
]]

local struct_tm_fields = {
  "tm_sec",
  "tm_min",
  "tm_hour",
  "tm_mday",
  "tm_mon",
  "tm_year",
  "tm_wday",
  "tm_yday",
  "tm_isdst",
}

local function struct_tm_to_lua(tm)
  return {
    sec = tm.tm_sec,
    min = tm.tm_min,
    hour = tm.tm_hour,
    day = tm.tm_mday,
    month = tm.tm_mon + 1,
    year = tm.tm_year + 1900,
    wday = tm.tm_wday + 1,
    yday = tm.tm_yday + 1,
    isdst = (tm.tm_isdst == 1),
  }
end

local date = {}

--[[ FIXME: UNTESTED
function date.getdate(str)
  local tm = ffi.new("struct tm")
  ffi.fill(tm, ffi.sizeof(tm))

  local err = ffi.C.getdate_r(str, tm)
  if err ~= 0 then
    if err == 1 then
      error("The DATEMSK environment variable is not defined, or its value is an empty string.")
    elseif err == 2 then
      error("The template file specified by DATEMSK cannot be opened for reading.")
    elseif err == 3 then
      error("Failed to get file status information.")
    elseif err == 4 then
      error("The template file is not a regular file.")
    elseif err == 5 then
      error("An error was encountered while reading the template file.")
    elseif err == 6 then
      error("Memory allocation failed (not enough memory available).")
    elseif err == 7 then
      error("There is no line in the file that matches the input.")
    elseif err == 8 then
      error("Invalid input specification.")
    else
      error("Unknown error: " .. err)
    end
  end

  return struct_tm_to_lua(tm)
end
]]

function date.strptime(str, fmt)
  local cstr = ffi.cast("const char *", str)
  local tm = ffi.new("struct tm")
  ffi.fill(tm, ffi.sizeof(tm))

  local fmt1, fmt2 = fmt:match("(.*)%%N(.*)")
  if fmt1 ~= nil and fmt2 ~= nil then
    local ret1 = ffi.C.strptime(cstr, fmt1, tm)
    if ret1 == nil then
      return 0, nil
    end

    local tm2 = ffi.new("struct tm")
    ffi.fill(tm2, ffi.sizeof(tm2))

    -- skip nanoseconds
    local ret1_ns = ffi.string(ret1):match("([0-9]+).*")
    local ret2 = ffi.C.strptime(ret1 + #ret1_ns, fmt2, tm2)
    if ret2 == nil then
      return 0, nil
    end

    for _,k in ipairs(struct_tm_fields) do
      if tm[k] == 0 then
        tm[k] = tm2[k]
      end
    end

    return (ret2 - cstr), struct_tm_to_lua(tm)
  end

  local ret = ffi.C.strptime(cstr, fmt, tm)
  if ret == nil then
    return 0, nil
  end

  return (ret - cstr), struct_tm_to_lua(tm)
end

return date
