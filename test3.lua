local http = require('http')

http.createServer(function (req, res)
  res:writeHead(200, {['Content-Type'] = 'text/plain'})
  res:finish('Hello World\n')
end):listen(1337, '127.0.0.1')

print('Server running at http://127.0.0.1:1337/')
