local fs = require('fs')

function favicon (path, options)
  local icon -- caching the icon

  if not options then options = {} end

  path = path or __dirname .. '/favicon.ico'
  maxAge = options.maxAge or 86400000

  return function (req, res, follow)
    if ('/favicon.ico' ~= req.url) then
      return follow()
    end

    if ('GET' ~= req.method and 'HEAD' ~= req.method) then
      local status = 'OPTIONS' == req.method and 200 or 405
      res:writeHead(status, {['Allow'] = 'GET, HEAD, OPTIONS'})
      return res:finish()
    end

    if (icon) then
      res:writeHead(304, icon.headers)
      res:finish(icon.body)
    else
      fs.readFile(path, function (err, buf)
        if (err) then follow(err) end

        icon = {
          body = buf,
          headers = {
            ['Content-Type'] = 'image/x-icon',
            ['Content-Length'] = #buf,
            ['Cache-Control'] = 'public, max-age=' .. (maxAge / 1000)
          }
        }

        res:writeHead(200, icon.headers)
        res:finish(buf)
      end)
    end
  end
end

return favicon
