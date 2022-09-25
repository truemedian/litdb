--[[lit-meta
    name = "tbmale/luvi-ffi"
    version = "0.0.2"
    dependencies = {}
    description = "search ffi in luvi bundle trying to follow arch-os-name convention"
    tags = { "luvi ffi bundle" }
    license = "MIT"
    author = { name = "ExtraVeral", email = "tbmale@yahoo.com" }
    homepage = "https://gitlab.com/tbmale/luvi-ffi"
  ]] 
  
local uv = require("uv")
local ffi = require("ffi")
local outffi = {}
local env = require("env")
local luvi = require('luvi')
local bundle = luvi.bundle

for k, v in pairs(ffi) do outffi[k] = v end

local tmpBase = ffi.os == "Windows" and (env.get("TMP") or uv.cwd()) or
                    (env.get("TMPDIR") or '/tmp')

local function load(name)
    local splitname = luvi.path.splitPath(name)
    local filename = table.remove(splitname, #splitname)
    local archosname = luvi.path.join(luvi.path.joinparts("", splitname),
                                      ffi.arch .. "-" .. ffi.os .. "-" ..
                                          filename)
    local inbundle = bundle.stat(archosname) and true or bundle.stat(name) and true or false
    if (not inbundle) then
        return uv.fs_stat(archosname) and ffi.load(archosname) or ffi.load(name)
    else
        local fdata = bundle.stat(archosname) and bundle.readfile(archosname) or
                          bundle.readfile(name)
        local fn = luvi.path.join(tmpBase, "bundleXXXXXX")
        local _ = assert(uv.fs_mkstemp(fn))
        local fd = uv.fs_open(fn, "w", 384)
        uv.fs_write(fd, fdata, 0)
        uv.fs_close(fd)
        local fp = ffi.load(fn)
        uv.fs_unlink(fn)
        return fp
    end
end

outffi["load"] = load
return outffi
