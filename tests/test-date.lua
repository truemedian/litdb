local date = require("date")
local deep_equal = require("deep-equal")

require("tap")(function(test)
  test("date-strptime", function()
    local str = "Fri Nov 20 15:18:40 CET 2015"
    local pos, got = date.strptime(str, "%a %b %d %T %Z %Y")
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
    assert(#str == pos)
    assert(deep_equal(expected, got))
  end)
  test("date-strptime-with-garbage-at-end", function()
    local str, garbage = "Fri Nov 20 15:18:40 CET 2015", "Lots of garbage"
    local pos, got = date.strptime(str .. garbage, "%a %b %d %T %Z %Y")
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
    assert(#str == pos)
    assert(deep_equal(expected, got))
  end)
  test("date-strptime-with-garbage-at-beginning", function()
    local str, garbage = "Fri Nov 20 15:18:40 CET 2015", "Lots of garbage"
    local pos, got = date.strptime(garbage .. str, "%a %b %d %T %Z %Y")
    assert(pos == 0)
    assert(got == nil)
  end)
  test("date-strptime-broken-format", function()
    local str = "Fri Nov 20 15:18:40 CET 2015"
    local pos, got = date.strptime(str, "%a %b %$")
    assert(pos == 0)
    assert(got == nil)
  end)
  test("date-strptime-empty-string", function()
    local pos, got = date.strptime("", "%a %b %d %T %Z %Y")
    assert(pos == 0)
    assert(got == nil)
  end)
end)
