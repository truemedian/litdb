
--[[
Copyright Kaustav Haldar
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

local path = require('path')
local scandir = require('fs').scandir
local timer = require('timer')

exports.readdirRecursive = function(baseDir, cb)
  baseDir = baseDir:gsub('%/$', '') -- strip trailing slash
  local filesList = {}

  local waitCount = 0

  local function readdirRecursive(curDir)

    local function prependcurDir(fname)
      return path.join(curDir, fname)
    end

    scandir(curDir, function(err, func)
      if err then return cb(err) end

      local function recurser(func)
        local name, type = func()

        if name and type then
          if type == 'directory' then
            waitCount = waitCount + 1
            timer.setImmediate(readdirRecursive, prependcurDir(name)) -- prevent potential buffer overflows
          elseif type == 'file' then
            table.insert(filesList, prependcurDir(name))
          end
          recurser(func)
        else
          waitCount = waitCount - 1
          if waitCount == 0 then return cb(nil, filesList) end
        end
      end

      recurser(func)
    end)
  end
  waitCount = waitCount + 1
  readdirRecursive(baseDir)
end
