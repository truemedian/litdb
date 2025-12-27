--[[lit-meta
  name = "nilfinx/response-time"
  version = "1.0.0"
  description = "voronianski/response-time for weblit"
  tags = {"luvit", "response-time", "header", "weblit", "middleware", "http"}
  license = "MIT"
  author = { name = "nilFinx" }
]]

local os = require('os')

require('on-headers-event')

-- round number to decimals, defaults to 2 decimals
function roundToDecimals (num, decimals)
  decimals = decimals or 2

  local shift = 10 ^ decimals
  local result = math.floor(num * shift + 0.5) / shift

  return result
end

function responseTime (opts)
  opts = opts or {}
  opts.header = opts.header or 'X-Response-Time'
  opts.suffix = opts.suffix or 'ms'

  return function (req, res, go)
    if res._responseTime then
      go()
    end

    local startTime = os.clock()

    res._responseTime = true
    go()

    local duration = roundToDecimals((os.clock() - startTime) * 1000)

    res.headers[opts.header] = duration .. opts.suffix
  end
end

return responseTime
