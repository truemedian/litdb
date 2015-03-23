luvit-split-stream
==================

[![Build Status](https://travis-ci.org/virgo-agent-toolkit/luvit-split-stream.svg?branch=master)](https://travis-ci.org/virgo-agent-toolkit/luvit-split-stream)

# Examples

A simple example where Split takes in fragmented input data and emits chunks separated by `\n`s.

```lua
local stream = require('stream')
local timer = require('timer')
local Split = require('split')
local table = require('table')

-- We'll use this source to simulate fragmented data
function getFragmentedSource(src_data)
  local len = #src_data
  local src = stream.Readable:new()
  src._read = function(this, n)
    for i=1,n do
      if 1 <= #src_data then
        local chunk = table.remove(src_data, 1)
        timer.setTimeout(i * 50, function()
          this:push(chunk)
        end)
      else
        timer.setTimeout((len + 1) * 50, function()
          this:push(nil)
        end)
      end
    end
  end

  return src
end

local src = getFragmentedSource({'chunk 1 ', 'chunk 2\n', 'line 2\nline 3\n'})

local sink = stream.Writable:new()
sink._write = function(this, data, encoding, callback)
  print('got chunk: ' .. data)
  callback()
end

src:pipe(Split:new()):pipe(sink)
```

Here's an example with some options. It uses 囧 rather than `\n` as separator, and uses a mapper function that reverses the string:

```lua
local stream = require('stream')
local string = require('string')
local timer = require('timer')
local Split = require('split')
local table = require('table')

-- We'll use this source to simulate fragmented data
function getFragmentedSource(src_data)
  local len = #src_data
  local src = stream.Readable:new()
  src._read = function(this, n)
    for i=1,n do
      if 1 <= #src_data then
        local chunk = table.remove(src_data, 1)
        timer.setTimeout(i * 50, function()
          this:push(chunk)
        end)
      else
        timer.setTimeout((len + 1) * 50, function()
          this:push(nil)
        end)
      end
    end
  end

  return src
end

local src = getFragmentedSource({'chunk 1 ', 'chunk 2囧', 'line 2囧line 3囧'})

local sink = stream.Writable:new()
sink._write = function(this, data, encoding, callback)
  print('got chunk: ' .. data)
  callback()
end

src:pipe(Split:new({
  separator = '囧',
  mapper = string.reverse,
})):pipe(sink)
```
