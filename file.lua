exports.name = "creationix/weblit-etag-cache"
exports.version = "0.1.1"
exports.description = "The etag-cache middleware caches WebLit responses in ram and uses etags to support conditional requests."
exports.tags = {"weblit", "middleware", "etag"}
exports.license = "MIT"
exports.author = { name = "Tim Caswell" }

local function clone(headers)
  local copy = setmetatable({}, getmetatable(headers))
  for i = 1, #headers do
    copy[i] = headers[i]
  end
  return copy
end

local cache = {}
return function (req, res, go)
  local requested = req.headers["If-None-Match"]
  local host = req.headers.Host
  local key = host and host .. "|" .. req.path or req.path
  local cached = cache[key]
  if not requested and cached then
    req.headers["If-None-Match"] = cached.etag
  end
  go()
  local etag = res.headers.ETag
  if not etag then return end
  if res.code >= 200 and res.code < 300 then
    local body = res.body
    if not body or type(body) == "string" then
      cache[key] = {
        etag = etag,
        code = res.code,
        headers = clone(res.headers),
        body = body
      }
    end
  elseif res.code == 304 then
    if not requested and cached and etag == cached.etag then
      res.code = cached.code
      res.headers = clone(cached.headers)
      res.body = cached.body
    end
  end
end
