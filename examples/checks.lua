#!/usr/bin/env luvit

--[[
Copyright 2012 Rackspace

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
local Client = require('./init').Client
local JSON = require('json')

--Configure
local argv = require('options')
  .usage("Usage: ./checks.lua -u <username> -k <apikey> -e <entity>")
  .describe("u", "username")
  .describe("k", "apikey")
  .describe("e", "entity")
  .demand({'u','k','e'})
  .argv("u:k:e:")


local client = Client:new(argv.args.u, argv.args.k, {})
client.checks.list(argv.args.e, function(err, results)
  if err then
    p(err)
    return
  end

  p(results.values)
end)

