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

-- a hacky fix for a luvit's require bug (see #1238)
-- we reverse this change after being done with it
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
return mod or error('luasql shared library could not be found. \n\
Try reinstalling the library otherwise a pre-built binary might not be available on this platform')
