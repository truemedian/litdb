--[[lit-meta
name = 'kaustavha/luvit-run'
version = '2.0.0'
license = 'MIT'
homepage = "https://github.com/kaustavha/luvit-run"
description = "Convenient utils for running shell commands, via lightweight streams or as a callback buffer"
tags = {"luvit", "childprocess", "run" }
dependencies = { 
  "luvit/luvit@2", 
  "virgo-agent-toolkit/line-emitter",
  "luvit/tap"
}
author = { name = 'Kaustav Haldar'}
]]
-- Internals --
local LineEmitter = require('line-emitter').LineEmitter
local Transform = require('stream').Transform
local childProcess = require('childprocess')

local Reader = Transform:extend()
function Reader:initialize()
  Transform.initialize(self, {objectMode = true})
end
function Reader:_transform(line, cb) 
  self:push(line)
  cb()
end

local function _execFileToStreams(command, args, options)
  local stdout, stderr = LineEmitter:new(), LineEmitter:new()
  local child = childProcess.spawn(command, args, options)
  child.stdout:pipe(stdout)
  child.stderr:pipe(stderr)
  return child, stdout, stderr
end

local function run(command, arguments, options)
  if not options then options = {} end
  local stream = Reader:new()
  local called, exitCode
  called = 2
  local function done()
    called = called - 1
    if called == 0 then
      if exitCode ~= 0 then
        stream:emit('error', 'Process exited with exit code ' .. exitCode)
      end
      stream:emit('end')
    end
  end
  local function onClose(_exitCode)
    exitCode = _exitCode
    done()
  end

  if not options.env then options.env = process.env end
  local child, stdout, stderr = _execFileToStreams(command, arguments, options)
  child:once('close', onClose)
  stdout:on('data', function(data) stream:emit('data', data) end):once('end', done)
  stderr:on('data', function(data) stream:emit('error', data) end)
  return stream
end
-- End internals --

function exports.runStream(command, arguments, options)
  return run(command, arguments, options)
end

function exports.run(command, arguments, options, cb)
  local errTable, outTable = {}, {}
  local reader = Reader:new()
  local child = run(command, arguments, options)
  reader:on('error', function(err)
    table.insert(errTable, err)
  end)
  reader:on('data', function(data)
    table.insert(outTable, data)
  end)
  reader:once('end', function()
    cb(errTable, outTable)
  end)
  child:pipe(reader)
end
