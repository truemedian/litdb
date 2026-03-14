local module_name = 'luasql_odbc'

local uv = require('uv')
local os = uv.os_uname().sysname:lower()
local pathjoin = require('luvipath').pathJoin

local scan_hnd = uv.fs_scandir(module.dir)
for name, kind in uv.fs_scandir_next, scan_hnd do
  if name:lower():find(os) and kind == 'directory' then
    return require(pathjoin(module.dir, name, module_name))
  end
end
