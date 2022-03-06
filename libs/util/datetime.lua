local function offset()
    return os.difftime(os.time(), os.time(os.date('!*t')))
end
  
local Format = "(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)"

return function (String)
    local year, month, day, hour, min, sec = String:match(Format)
    return os.time {
      year = year, month = month, day = day,
      hour = hour, min = min, sec = sec, isdst = false,
    } + offset()
end