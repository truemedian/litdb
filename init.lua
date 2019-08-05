
local uv = require 'uv'
local jit = require 'jit'
local bit = require 'bit'

local lfs = { }

function lfs.attributes(path, aname, atable)
    atable = atable or { }

    local stat = uv.fs_stat(path)

    local perms = table.concat { 
        bit.band(stat.mode, 256) > 0 and 'r' or '-',
        bit.band(stat.mode, 128) > 0 and 'w' or '-',
        bit.band(stat.mode, 64) > 0 and 'x' or '-',
        bit.band(stat.mode, 32) > 0 and 'r' or '-',
        bit.band(stat.mode, 16) > 0 and 'w' or '-',
        bit.band(stat.mode, 8) > 0 and 'x' or '-',
        bit.band(stat.mode, 4) > 0 and 'r' or '-',
        bit.band(stat.mode, 2) > 0 and 'w' or '-',
        bit.band(stat.mode, 1) > 0 and 'x' or '-',
    }

    atable.dev = stat.dev
    atable.ino = stat.ino
    atable.mode = stat.type
    atable.nlink = stat.nlink
    atable.uid = stat.uid
    atable.gid = stat.gid
    atable.rdev = stat.rdev
    atable.access = stat.atime.sec
    atable.modification = stat.mtime.sec
    atable.change = stat.ctime.sec
    atable.size = stat.size
    atable.permissions = perms
    atable.blocks = stat.blocks
    atable.blksize = stat.blksize

    if aname then
        return atable[aname]
    else
        return atable
    end
end

function lfs.chdir(path)
    return uv.chdir(path)
end

function lfs.currentdir()
    return uv.cwd()
end

local function dir_close(self)
    self.closed = true
    return uv.cancel(self.req)
end

local function dir_iter(self)
    assert(not self.closed, 'closed directory')

    local ent = uv.fs_scandir_next(self.req)
    if not ent then
        dir_close(self)
        return nil
    end

    if type(ent) == 'table' then
        return ent.name
    else
        return ent
    end
end

local dir_metatable = {
    next = dir_iter,
    close = dir_close
}

function lfs.dir(path)
    local req = assert(uv.fs_scandir(path))

    return dir_iter, setmetatable({
        req = req, closed = false
    }, {
        __index = dir_metatable,
        __gc = dir_close
    })
end

function lfs.link(old, new, symlink)
    if symlink then
        return uv.fs_symlink(old, new)
    else
        return uv.fs_link(old, new)
    end
end

function lfs.mkdir(dirname)
    return uv.fs_mkdir(dirname, 775)
end

function lfs.rmdir(dirname)
    return uv.fs_rmdir(dirname)
end

if jit.os == 'Windows' then
    lfs.symlinkattributes = lfs.attributes
else
    function lfs.symlinkattributes(filepath, aname)
        local atable = { }

        local stat = uv.fs_stat(filepath)

        local perms = table.concat { 
            bit.band(stat.mode, 256) > 0 and 'r' or '-',
            bit.band(stat.mode, 128) > 0 and 'w' or '-',
            bit.band(stat.mode, 64) > 0 and 'x' or '-',
            bit.band(stat.mode, 32) > 0 and 'r' or '-',
            bit.band(stat.mode, 16) > 0 and 'w' or '-',
            bit.band(stat.mode, 8) > 0 and 'x' or '-',
            bit.band(stat.mode, 4) > 0 and 'r' or '-',
            bit.band(stat.mode, 2) > 0 and 'w' or '-',
            bit.band(stat.mode, 1) > 0 and 'x' or '-',
        }

        atable.dev = stat.dev
        atable.ino = stat.ino
        atable.mode = stat.type
        atable.nlink = stat.nlink
        atable.uid = stat.uid
        atable.gid = stat.gid
        atable.rdev = stat.rdev
        atable.access = stat.atime.sec
        atable.modification = stat.mtime.sec
        atable.change = stat.ctime.sec
        atable.size = stat.size
        atable.permissions = perms
        atable.blocks = stat.blocks
        atable.blksize = stat.blksize

        if stat.type == 'link' then
            atable.target = uv.fs_readlink(filepath)
        end

        if aname then
            return atable[aname]
        else
            return atable
        end
    end
end

function lfs.touch(filepath, atime, mtime)
    return uv.fs_utime(filepath, atime, mtime)
end

function lfs.setmode(file, mode)
    return error('lfs.setmode not implemented')
end

function lfs.lock_dir(path, seconds_stale)
    return error('lfs.lock_dir not implemented')
end

function lfs.lock(filehandle, mode, start, length)
    return error('lfs.lock not implemented')
end

function lfs.unlock(filehandle, start, length)
    return error('lfs.unlock not implemented')
end

return lfs