--[[
Copyright 2013-2015 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]
local uv = require('uv')
local Object = require('core').Object
local async = require('async')
local dns = require('dns')
local fmt = require('string').format
local logging = require('logging')
local misc = require('../util/misc')

local Endpoint = Object:extend()

function Endpoint:initialize(host, port, srv_query)
  if not port and host then
    local ip_and_port = misc.splitAddress(host)
    host = ip_and_port[1]
    port = ip_and_port[2]
  end

  self.host = host
  self.port = port
  self.srv_query = srv_query
end


--[[
Determine the Hostname, IP and Port to use for this endpoint.

For static endpoints we just return our host and port, but for SRV
endpoints we query DNS.
--]]
function Endpoint:getHostInfo(callback)
  local ip, host, port

  async.series({
    function (callback)
      if self.srv_query then
        dns.resolveSrv(self.srv_query, function(err, results)
          if err or #results == 0 then
            logging.errorf('Could not lookup SRV record for %s', self.srv_query)
            callback(err)
            return
          end
          host = results[1].target
          port = results[1].port
          logging.debugf('SRV:%s -> %s:%d', self.srv_query, host, port)
          callback()
        end)
      else
        host = self.host
        port = self.port
        callback()
      end
    end,
    function (callback)
      uv.getaddrinfo(host, nil, { socktype = 'stream' }, function(err, ipa)
        if err then
          return callback(err)
        end
        ip = ipa[1].addr
        callback()
      end)
    end
  },
  function(err)
    if err then
      return callback(err)
    end
    callback(nil, host, ip, port)
  end)

end

function Endpoint.meta.__tostring(table)
  if table.srv_query then
    return fmt("SRV:%s", table.srv_query)
  else
    return fmt("%s:%s", table.host, table.port)
  end
end

exports.Endpoint = Endpoint
