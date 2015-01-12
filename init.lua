--[[
Copyright 2015 Virgo Agent Toolkit Authors

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
local Writable = require('stream_writable').Writable
local fs = require('fs')
local format = require('string').format
local los = require('los')
local table = require('table')
local utils = require('utils')

-------------------------------------------------------------------------------

local reverseMap = function(t)
  local res = {}
  for k, v in pairs(t) do
    res[v] = k
  end
  return res
end

-------------------------------------------------------------------------------

local EOL

if los.type() == 'win32' then
  EOL = '\r\n'
else
  EOL = '\n'
end

local Logger = Writable:extend()

Logger.LEVELS = {
  ['nothing'] = 0,
  ['critical'] = 1,
  ['error'] = 2,
  ['warning'] = 3,
  ['info'] = 4,
  ['debug'] = 5,
  ['everything'] = 6,
}

Logger.LEVEL_STRS = {
  [1] = ' CRT: ',
  [2] = ' ERR: ',
  [3] = ' WRN: ',
  [4] = ' INF: ',
  [5] = ' DBG: ',
  [6] = ' UNK: ',
}

Logger.REVERSE_LEVELS = reverseMap(Logger.LEVELS)

function Logger:initialize(options)
  Writable.initialize(self)
  self.options = options or {}
  self.log_level = self.options.log_level or self.LEVELS['warning']
end

function Logger:_log_buf(str)
  self:write(str)
end

function Logger:_log(level, str)
  if self.log_level < level then
    return
  end

  if #str == 0 then
    return
  end

  local bufs = {}
  table.insert(bufs, os.date('%a %b %d %X %Y'))
  table.insert(bufs, self.LEVEL_STRS[level])
  table.insert(bufs, str)
  table.insert(bufs, EOL)

  self:_log_buf(table.concat(bufs))
end

function Logger:_logf(level, fmt, ...)
  self:_log(level, format(fmt, ...))
end

-------------------------------------------------------------------------------

local FileLogger = Logger:extend()
function FileLogger:initialize(options)
  Logger.initialize(self, options)
  assert(self.options.path, "path is missing")
  self._path = self.options.path
  self._stream = fs.WriteStream:new(self._path, self.options)
  self:on('finish', utils.bind(self.close, self))
end

function FileLogger:close()
  self._stream:_end()
end

function FileLogger:_write(data, encoding, callback)
  self._stream:write(data, encoding, callback)
end

function FileLogger:rotate()
  self._stream:cork() -- buffer writes
  self._stream:open() -- reopen
  self:once('open', utils.bind(self._stream.uncork, self._stream)) -- uncork
end

-------------------------------------------------------------------------------

local StderrLogger = Logger:extend()
function StderrLogger:initialize(options)
  options = options or { fd = 2 }
  Logger.initialize(self, options)
  self._stream = fs.WriteStream:new(self._path, self.options)
end

function StderrLogger:close()
  self._stream:_end()
end

function StderrLogger:_write(data, encoding, callback)
  self._stream:write(data, encoding, callback)
end

-------------------------------------------------------------------------------

local function init(stream)
  for k, i in pairs(stream.LEVELS) do
    exports[k] = utils.bind(stream._log, stream, i)
    exports[k .. 'f'] = utils.bind(stream._logf, stream, i)
    exports[k:upper()] = i
  end

  exports.log = utils.bind(stream._log, stream)
end

-------------------------------------------------------------------------------

-- Base Logger
exports.Logger = Logger

-- File Logger
exports.FileLogger = FileLogger

-- Stderr Logger
exports.StderrLogger = StderrLogger

-- Sets up exports[LOGGER_LEVELS] for easy logging
exports.init = init

init(StderrLogger:new())
