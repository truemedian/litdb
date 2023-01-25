local http = require 'coro-http'
local json = require 'json'

local request = http.request

local Books = {
  CHEROKEE = 'cherokee',
  BBE = 'bbe',
  KJV = 'kjv',
  WEB = 'web',
  OEBCW = 'oeb-cw',
  WEBBE = 'webbe',
  OEBUS = 'oeb-us',
  CLEMENTINE = 'clementine',
  ALMEIDA = 'almeida',
  RCCV = 'rccv'
}

local function fetch (book, chapter, ranges, translation)
  local base = 'https://bible-api.com/%s %s:%s?translation=%s'
  local url = string.format(base, book, chapter, ranges, translation)

  local res, data = request("GET", url)

  if res.code == 200 then
    return (json.parse(data)).verses
  else
    error("Failed to retrieve verse", 2)
  end
end

return {
  Books = Books,

  Preach = function (args)
    local book = args.book
    local chapter = args.chapter
    local translation = args.translation or Books.KJV

    local ranges = ""

    for _, range in ipairs(args.ranges) do
        ranges = ranges .. range .. ','
    end

    ranges = string.sub(ranges, 1, #ranges-1)

    return fetch(book, chapter, ranges, translation)
  end
}
