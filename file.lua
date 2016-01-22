--[[lit-meta
name = 'kaustavha/luvit-stat'
version = '1.0.0'
license = 'MIT'
homepage = "https://github.com/kaustavha/luvit-stat"
description = "A luvit stat function that returns file permissions data that makes sense"
tags = {"luvit", "stat"}
dependencies = { 
  "luvit/luvit@2",
  "luvit/tap"
}
author = { name = 'Kaustav Haldar'}
]]
local fs = require('fs')
local exists = fs.exists
local stat = fs.stat
local band = bit.band
local fmt = string.format

function exports.stat(file, cb)
    local errTable = {}
    exists(file, function(err, data)
      if err or not data then
        --[[This error may occasionally warn us of missing files, we can ignore it or use it upstream]]--
        table.insert(errTable, fmt('fs.exists in fileperms.lua erred: %s', err))
        return cb()
      end
      stat(file, function(err, fstat)
        if err or not fstat then
          table.insert(errTable, fmt('fs.stat in fileperms.lua erred: %s', err))
          return cb(errTable, outTable)
        end
        local obj = {}
        obj.fileName = file
        --[[Check file permissions, octal: 0777]]--
        obj.octalFilePerms = string.format("%o", band(fstat.mode, 511))
        --[[Check if the file has a sticky id, octal: 01000]]--
        obj.stickyBit = band(fstat.mode, 512) ~= 0
        --[[Check if file has a set group id, octal: 02000]]--
        obj.setgid = (band(fstat.mode, 1024) ~= 0)
        --[[Check if the file has a set user id, octal: 04000]]--
        obj.setuid = (band(fstat.mode, 2048) ~= 0)
        return cb(errTable, obj)
      end)
    end)
end
