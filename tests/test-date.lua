local date = require("date")
local deepEqual = require("deep-equal")

require("tap")(function(test)
  test("date-strptime-simple-date", function()
    local str = "Jan 01 1970"
    local pos, got = date.strptime(str, "%b %d %Y")
    local expected = {
      year = 1970,
      month = 1,
      day = 1,
      hour = 0,
      min = 0,
      sec = 0,
      wday = 5,
      yday = 1,
      isdst = false,
    }
    assert(deepEqual(#str, pos))
    assert(deepEqual(expected, got))
  end)
  test("date-strptime-simple-time", function()
    local str = "01:02:03"
    local pos, got = date.strptime(str, "%T")
    local expected = {
      year = 1900,
      month = 1,
      day = 0,
      hour = 1,
      min = 2,
      sec = 3,
      wday = 1,
      yday = 1,
      isdst = false,
    }
    assert(deepEqual(#str, pos))
    assert(deepEqual(expected, got))
  end)
  test("date-strptime-simple-timezone", function()
    local str = "+0100"
    local pos, got = date.strptime(str, "%z")
    local expected = {
      year = 1900,
      month = 1,
      day = 0,
      hour = 0,
      min = 0,
      sec = 0,
      wday = 1,
      yday = 1,
      isdst = false,
    }
    assert(deepEqual(#str, pos))
    assert(deepEqual(expected, got))
  end)
  test("date-strptime-complete", function()
    local str = "Fri Nov 20 15:18:40 -0130 2015"
    local pos, got = date.strptime(str, "%a %b %d %T %z %Y")
    local expected = {
      year = 2015,
      month = 11,
      day = 20,
      hour = 15,
      min = 18,
      sec = 40,
      wday = 6,
      yday = 324,
      isdst = false,
    }
    assert(deepEqual(#str, pos))
    assert(deepEqual(expected, got))
  end)
  test("date-strptime-iso-8601", function()
    local str = "2015-12-03T20:32:29.441862132+0000"
    local pos, got = date.strptime(str, "%Y-%m-%dT%H:%M:%S.%N%z")
    local expected = {
      year = 2015,
      month = 12,
      day = 03,
      hour = 20,
      min = 32,
      sec = 29,
      wday = 5,
      yday = 337,
      isdst = false,
    }
    assert(deepEqual(#str, pos))
    assert(deepEqual(expected, got))
  end)
  test("date-strptime-iso-8601-broken-front", function()
    local str = "2015-12-0320:32:29.441862132+0000"
    local pos, got = date.strptime(str, "%Y-%m-%dT%H:%M:%S.%N%z")
    assert(deepEqual(0, pos))
    assert(deepEqual(nil, got))
  end)
  test("date-strptime-iso-8601-broken-back", function()
    local str = "2015-12-03T20:32:29.441862132%0000"
    local pos, got = date.strptime(str, "%Y-%m-%dT%H:%M:%S.%N%z")
    assert(deepEqual(0, pos))
    assert(deepEqual(nil, got))
  end)
  test("date-strptime-with-garbage-at-end", function()
    local str, garbage = "Fri Nov 20 15:18:40 -0130 2015", "Lots of garbage"
    local pos, got = date.strptime(str .. garbage, "%a %b %d %T %z %Y")
    local expected = {
      year = 2015,
      month = 11,
      day = 20,
      hour = 15,
      min = 18,
      sec = 40,
      wday = 6,
      yday = 324,
      isdst = false,
    }
    assert(deepEqual(#str, pos))
    assert(deepEqual(expected, got))
  end)
  test("date-strptime-with-garbage-at-beginning", function()
    local str, garbage = "Fri Nov 20 15:18:40 -0130 2015", "Lots of garbage"
    local pos, got = date.strptime(garbage .. str, "%a %b %d %T %z %Y")
    assert(deepEqual(0, pos))
    assert(deepEqual(nil, got))
  end)
  test("date-strptime-broken-format", function()
    local str = "Fri Nov 20 15:18:40 -0130 2015"
    local pos, got = date.strptime(str, "%a %b %$")
    assert(deepEqual(0, pos))
    assert(deepEqual(nil, got))
  end)
  test("date-strptime-empty-string", function()
    local pos, got = date.strptime("", "%a %b %d %T %z %Y")
    assert(deepEqual(0, pos))
    assert(deepEqual(nil, got))
  end)
end)
