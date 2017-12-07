local http = require "http"
local qs = require "querystring"

function exports.createServer(f)
  return http.createServer(function(req, res)
    local cookies
    for i, v in ipairs(req.headers) do
      if v[1] == "Cookie" then
        cookies = v[2]
      end
    end
    if cookies and cookies == "cookiesRequired=true" then
      return f(req, res)
    elseif req.url:find("^/set%-cookie%?") then
      res.statusCode = 302
      res:setHeader("Location", qs.urldecode(req.url:match("^/set%-cookie%?(.+)")))
      res:setHeader("Set-Cookie", "cookiesRequired=true; Max-Age=" .. 60*60*24*365)
      res:setHeader("Content-Type", "text/html")
      res:finish([[
<!DOCTYPE html>
<html>
  <head>
    <title>Cookies Required</title>
  </head>
  <body>
    <p>You're all set, but your browser doesn't appear to follow redirects.<p>
    <p>Just hit the "back" button or repeat the original request!</p>
  </body>
</html>
]])
    else
      res.statusCode = 402
      res.statusMessage = "Cookies Required"
      res:setHeader('Cookies-Required', "cookiesRequired=true; Max-Age=" .. 60*60*24*365)
      res:setHeader("Content-Type", "text/html")
      res:finish([[
<!DOCTYPE html>
<html>
  <head>
    <title>Cookies Required</title>
  </head>
  <body>
    <p>This website requires cookies</p>
    <p><a href="/set-cookie?]].. qs.urlencode(req.url) ..[[">I accept</a></p>
  </body>
</html>
]])
    end
  end)
end
