--[[lit-meta
name = "truemedian/luvit-fswatch"
version = "1.0.0"
dependencies = { }
description = "A nice wrapper around the libuv fs events interface, making integrating much easier"
tags = { "luvit", "luv", "libuv", "fs" }
license = "MIT"
author = { name = "Nameless", email = "truemedian@gmail.com" }
homepage = "https://github.com/truemedian/luvit-fswatch"
]]

local uv = require 'uv'
local pathjoin = require 'pathjoin'

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
    fs_event:start(normal_filepath, { recursive = recursive }, function(err, file_changed, ctx)
        if err then return callback(err, nil, nil, nil) end

        if file_changed:find('\\') then
            file_changed = file_changed:gsub('\\', '/')
        end

        local file_changed_path = normal_filepath .. '/' .. file_changed

        local stat, stat_err, stat_code = uv.fs_stat(file_changed_path)
        if not stat and stat_code ~= 'ENOENT' then callback(stat_err, nil, nil, nil) end

        if ctx.rename then
            if stat then
                callback(nil, 'created', file_changed, stat)
            else
                callback(nil, 'removed', file_changed, nil)
            end
        elseif ctx.change then
            if stat.type == 'directory' then
                callback(nil, 'directory_changed', file_changed, stat)
            else
                callback(nil, 'file_changed', file_changed, stat)
            end
        else
            callback('unknown event type in watcher', nil, nil, nil)
        end
    end)

    return {
        handle = fs_event,
        stop = function()
            fs_event:stop()
        end
    }
end

return {
    watch = watch
}