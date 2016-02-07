--[[
 * parseurl from https://github.com/pillarjs/parseurl
 * Copyright(c) 2014 Jonathan Ong
 * Copyright(c) 2014 Douglas Christopher Wilson
 * MIT Licensed
]]

--[[
 * Module dependencies.
]]

local parse = require('url').parse

local function Url()
  return {
    protocol = nil,
    slashes = nil,
    auth = nil,
    host = nil,
    port = nil,
    hostname = nil,
    hash = nil,
    search = nil,
    query = nil,
    pathname = nil,
    path = nil,
    href = nil
  }
end

--[[
 * Pattern for a simple path case.
 * See: https://github.com/joyent/node/pull/7878
]]

-- does the url contain a `?` or a `=`
local simplePathRegExp = "[%?]*[%=]*"


--[[
 * Parse the `str` url with fast-path short-cut.
 *
 * @param {string} str
 * @return {table}
 * @api private
]]

local function fastparse(str)
  assert(type(str), 'string')

  local simplePath = { str:match(simplePathRegExp) }

  -- can we skip url.parse?
  if (#simplePath > 1) then
    local url = Url()

    url.path = str
    url.href = str
    url.pathname = str
    url.search = nil
    url.query = nil

    return url
  end

  return parse(str)
end

--[[
 * Determine if parsed is still fresh for url.
 *
 * @param {string} url
 * @param {table} parsedUrl
 * @return {boolean}
 * @api private
]]

local function fresh(url, parsedUrl)
  return type(parsedUrl) == 'table'
    and parsedUrl ~= nil
    -- and (Url == nil or parsedUrl instanceof Url)
    and parsedUrl._raw == url
end

--[[
 * Parse the `req` url with memoization.
 *
 * @param {ServerRequest} req
 * @return {table}
 * @api public
]]

local function parseurl(req)
  local url = req.url or nil

  if (url == nil) then
    -- URL is nil
    return nil
  end

  local parsed = req._parsedUrl

  if (fresh(url, parsed)) then
    -- Return cached URL parse
    return parsed
  end

  -- Parse the URL
  parsed = fastparse(url)
  parsed._raw = url

  req._parsedUrl = parsed

  return req._parsedUrl
end

--[[
 * Parse the `req` original url with fallback and memoization.
 *
 * @param {ServerRequest} req
 * @return {table}
 * @api public
]]

local function originalurl(req)
  local url = req.originalUrl

  if (type(url) ~= 'string') then
    -- Fallback
    return parseurl(req)
  end

  local parsed = req._parsedOriginalUrl

  if (fresh(url, parsed)) then
    -- Return cached URL parse
    return parsed
  end

  -- Parse the URL
  parsed = fastparse(url)
  parsed._raw = url

  req._parsedOriginalUrl = parsed
  return req._parsedOriginalUrl
end

--[[
 * Exports.
]]

return {
  parseurl = parseurl,
  original = originalurl
}