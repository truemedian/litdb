local uv = require 'uv'
local os = require 'os'

local host = os.getenv("HOST") or "0.0.0.0"
local port = os.getenv("PORT") or 8080
local baseDir = os.getenv("BASE_DIR") or uv.cwd()

print("BASE_DIR:", baseDir)
print("HOST:    ", host)
print("PORT:    ", port)

require('weblit-app')
  .bind {host = host, port = port }

 -- Set an outer middleware for logging requests and responses
  .use(require('weblit-logger'))

  -- This adds missing headers, and tries to do automatic cleanup.
  .use(require('weblit-auto-headers'))

  .route({
    method = "GET",
    path = "/package/:path:"
  }, require('serve-mpk')(baseDir))

  -- Bind the ports, start the server and begin listening for and accepting connections.
  .start()

  require('uv').run()

