--[[
Copyright 2015 Virgo Agent Toolkit Authors
Copyright Tomaz Muraus

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

local Transform = require('stream').Transform

local LineEmitter = Transform:extend()

function LineEmitter:initialize(initialBuffer, options)
  options = options or {}
  options.objectMode = true
  Transform.initialize(self, options)
  self._buffer = initialBuffer and initialBuffer or ''
  self._includeNewLine = options['includeNewLine']
end

function LineEmitter:_write(chunk, encoding, callback)
  local line

  if not chunk then
    return self:push()
  end

  self._buffer = self._buffer .. chunk

  line = self:_popLine()
  while line do
    self:push(line)
    line = self:_popLine()
  end

  callback()
end

function LineEmitter:_popLine()
  local line = false
  local index = self._buffer:find('\n')

  if index then
    line = self._buffer:sub(0, index - 1)

    if self._includeNewLine then
      line = line .. '\n'
    end

    self._buffer = self._buffer:sub(index + 1)
  end

  return line
end

exports.LineEmitter = LineEmitter
