--[[
https://github.com/lunarmodules/luasql
https://lunarmodules.github.io/luasql/

Copyright © 2003-2026 The Kepler Project.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- This init file is basically a workaround for 2 bugs,
-- First one happened in lit 2.15.0, which broke the naming scheme
-- for the `$ARCH` variable used by package.lua, so now we have
-- to search for both `$OS-x64` *and* `$OS-x86_64`.
-- Second one is in luvit's require on Windows, where fixed paths
-- do not work (i.e. C:/a/b/c), as it thinks the path is a module name.
-- We workaround that by changing the entire module directory into
-- the found `$OS-$ARCH` directory, then using a relative require.
-- This workaround also ensures that this library also works when embedded in a luvi app.

local module_name = 'luasql_odbc'

local uv = require('uv')
local os = uv.os_uname().sysname:lower():match('%P+')

local luvi = require('luvi')
local is_bundle = module.path:match('^@?bundle:.*') and true or false
local pathjoin = luvi.path.join
local stat = is_bundle and luvi.bundle.stat or uv.fs_stat

local dirs = {
  'Windows-x64',
  'Windows-x86_64',
  'Linux-x64',
  'Linux-x86_64',
}

local org_dir = module.dir
local module_dir = module.dir:gsub('^@?bundle:', '')

local mod
for _, dir_name in ipairs(dirs) do
  local dir_path = pathjoin(module_dir, dir_name)
  if dir_name:lower():find(os) and stat(dir_path) then
    module.dir = pathjoin(module.dir, dir_name)
    mod = require('./' .. module_name)
    if mod then
      break
    end
  end
end

module.dir = org_dir
return mod or error('luasql shared library could not be found. \
Try reinstalling the library, otherwise a pre-built binary might not be available on this platform')
