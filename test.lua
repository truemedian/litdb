local https = require('https')
local fs = require('fs')

local options = {
  key = fs.readFileSync('server.key.insecure'),
  cert = fs.readFileSync('server.crt')
}
local server = https.createServer(options, function(req, res)
  res:write('hello world\n')
  res:finish()
end)
server:listen(8080, '127.0.0.1')

