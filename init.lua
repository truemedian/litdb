--[[lit-meta
name = "truemedian/luvit-fswatch"
version = "1.1.0"
dependencies = { }
description = "A nice wrapper around the libuv fs events interface, making integrating much easier"
tags = { "luvit", "luv", "libuv", "fs" }
license = "MIT"
author = { name = "Nameless", email = "truemedian@gmail.com" }
homepage = "https://github.com/truemedian/luvit-fswatch"
]]

local uv = require 'uv'
local fs = require 'fs'
local pathjoin = require 'pathjoin'

local function cache_directory(path, collector, recursive)
    assert(uv.fs_stat(path), 'the directory "' .. path .. '" does not exist')

    for file, ftype in fs.scandirSync(path) do
        local this_path = path .. '/' .. file
        if ftype == 'directory' and recursive then
            cache_directory(this_path, collector, recursive)
        end

        local stat, stat_err = uv.fs_stat(this_path)

        if stat then
            collector[this_path] = stat
        else
            print(stat_err)
        end
    end
end

--- watch(filepath[, recursive], callback)
---  callback(err, event, filepath, stat)
local function watch(filepath, recursive, callback)
    if type(recursive) == 'function' then
        callback = recursive
        recursive = nil
    end

    assert(type(filepath) == 'string', "expected string filepath to function 'watch'")
    assert(type(callback) == 'function', "expected function callback to function 'watch'")

    local fs_event = uv.new_fs_event()

    local normal_filepath = pathjoin.joinParts(nil, pathjoin.splitPath(filepath))

    assert(uv.fs_stat(normal_filepath))

    local stat_cache = { }
    cache_directory(normal_filepath, stat_cache, recursive)

    fs_event:start(normal_filepath, { recursive = recursive }, function(err, file_changed, ctx)
        if err then return callback(err, nil, nil, nil) end

        if file_changed:find('\\') then
            file_changed = file_changed:gsub('\\', '/')
        end

        local file_changed_path = normal_filepath .. '/' .. file_changed

        local new_stat, stat_err, stat_code = uv.fs_stat(file_changed_path)
        if not new_stat and stat_code ~= 'ENOENT' then callback(stat_err, nil, nil, nil) end

        local old_stat = stat_cache[file_changed_path]

        if ctx.rename then
            if new_stat then
                stat_cache[file_changed_path] = new_stat
                callback(nil, 'created', file_changed, new_stat)
            else
                callback(nil, 'removed', file_changed, old_stat)
            end
        elseif ctx.change then
            if new_stat then -- check if directory was removed
                if new_stat.type == 'directory' then
                    stat_cache[file_changed_path] = new_stat
                    callback(nil, 'directory_changed', file_changed, new_stat)
                else
                    stat_cache[file_changed_path] = new_stat
                    if new_stat.size ~= old_stat.size then
                        callback(nil, 'file_changed', file_changed, new_stat)
                    end
                end
            end
        else
            callback('unknown event type in watcher', nil, nil, nil)
        end
    end)

    return {
        _handle = fs_event,
        _cache = stat_cache,
        stop = function()
            fs_event:stop()
        end
    }
end

watch('./tester', true, function(err, event, path, stat)
    p(event, path, stat and stat.size or -1, err)
end)

return {
    watch = watch
}