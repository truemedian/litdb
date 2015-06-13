local fs = require('fs')
local https = require('https')
local http = require('http')
 
local opts = {
  host = 'agent-endpoint-dfw.monitoring.api.rackspacecloud.com',
  path = '/upgrades/test/rackspace-monitoring-agent-x64.msi',
  rejectUnauthorized = false
}

--local opts = {
--  host = 'gensho.acc.umu.se',
--  path = '/mirror/ubuntu-releases/14.04.2/ubuntu-14.04.2-server-amd64.iso'
--}

-- local opts = {
--   host = 'gensho.acc.umu.se',
--   path = '/mirror/ubuntu-releases/14.04.2/ubuntu-14.04.2-server-amd64.iso',
--    rejectUnauthorized = false
-- }
 
local req = https.request(opts, function(res)
  local stream = fs.createWriteStream('out.msi')
  stream:on('end', function()
    p(res.headers['content-length'])
  end)
  res:pipe(stream)
end)
req:done()
