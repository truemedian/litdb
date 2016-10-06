local url = require('url')
local methods = require('http-methods')
local matchPath = require('match-path')

local route = {}

function matches (reqMethod, method)
  if not method then return true end
  if reqMethod == method then return true end
  if method == 'GET' and reqMethod == 'HEAD' then return true end
  return false
end

function create (method)
  if method then
    method = method:upper()
  end

  function createHandle (path, fn, opts)
    opts = opts or {}

    function handle (req, res, nxt)
      if not matches(req.method, method) then
        return nxt()
      end

      local parsedUrl = url.parse(req.url)
      local pathname = parsedUrl.pathname
      local pathnameLen = #pathname

      if pathname:sub(pathnameLen) == '/' and not opts.keepTrailingSlash then
        pathname = pathname:sub(1, pathnameLen - 1)
      end

      local parsePath = matchPath.compile(path)
      local params = parsePath(pathname)

      if not params then
        return nxt()
      end

      req.params = params

      return fn(req, res, nxt)
    end

    return handle
  end

  return createHandle
end

for i, method in ipairs(methods) do
  route[method] = create(method)
end

route.del = route.delete
route.all = create()

return route
