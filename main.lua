--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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

local bundle = require('luvi').bundle
loadstring(bundle.readfile("luvit-loader.lua"), "bundle:luvit-loader.lua")()

local uv = require('uv')
require('snapshot')
local aliases = {
  ["-v"] = "version",
  ["-h"] = "help",
}

local function exit(status)
  uv.walk(function(handle)
    if handle then
      local function close()
        if not handle:is_closing() then handle:close() end
      end
      if handle.shutdown then
        handle:shutdown(close)
      else
        close()
      end
    end
  end)
  uv.run()
  os.exit(status)
end

_G.p = require('pretty-print').prettyPrint
local version = require('./package').version
coroutine.wrap(function ()
  local log = require('log').log
  local command = args[1] or "help"
  if command:sub(1, 2) == "--" then
    command = command:sub(3)
  end
  command = aliases[command] or command
  local invalid = false
  local success, err = xpcall(function ()
    log("lit version", version)
    log("luvi version", require('luvi').version)
    if command == "version" then exit(0) end
    local path = "./commands/" .. command .. ".lua"
    if bundle.stat(path:sub(3)) then
      log("command", table.concat(args, " "), "highlight")
    else
      invalid = command
      log("invalid command", command, "failure")
      command = "help"
      path = "./commands/" .. command .. ".lua"
    end
    require(path)()
  end, debug.traceback)
  if invalid then
    success = false
    err = "Invalid Command: " .. invalid
  end
  if success then
    log("done", "success", "success")
    print()
    exit(0)
  else
    log("fail", err, "failure")
    print()
    exit(-1)
  end
end)()
uv.run()
