exports.name = 'kaustavha/luvit-read'
exports.version = '1.0.0'
exports.license = 'MIT'
exports.homepage = "https://github.com/kaustavha/luvit-read"
exports.description = "Convenient utils for reading files, via lightweight streams or as a callback buffer"
exports.tags = {"luvit", "fs", "read" }
exports.dependencies = { 
  "luvit/luvit@2", 
  "virgo-agent-toolkit/luvit-line-emitter",
  "luvit/tap"
}
exports.author = { name = 'Kaustav Haldar'}

local Transform = require('stream').Transform
local fs = require('fs')
local LineEmitter = require('line-emitter').LineEmitter

-- Internal --
local Reader = Transform:extend()
function Reader:initialize()
  Transform.initialize(self, {objectMode = true})
end

local function _read(filePath, Stream)
  local outStream = Stream:new()
  local readable = fs.createReadStream(filePath)
  -- Prolly a file not found error at this stage, pump it out
  readable:on('error', function(err) outStream:emit('error', err) end)
  readable:pipe(LineEmitter:new()):pipe(outStream)
  return outStream
end

local function readClean(filePath)
  local Stream = Reader:extend()
  function Stream:_transform(line, cb)
    if line then
      local iscomment = string.match(line, '^#')
      local isblank = string.len(line:gsub("%s+", "")) <= 0
      if not iscomment and not isblank then
        self:push(line)
      end
    end
    cb()
  end
  return _read(filePath, Stream)
end

local function readNormal(filePath)
  local Stream = Reader:extend()
  function Stream:_transform(line, cb)
    self:push(line)
    cb()
  end
  return _read(filePath, Stream)
end

function readCb(filePath, ReadStream, cb)
  local readData = {}
  local errData = {}
  local Stream = Reader:extend()
  function Stream:_transform(line, cb)
    self:push(line)
    cb()
  end
  local readStream = ReadStream(filePath)
  local outStream = Stream:new()
  outStream:on('data', function(data) 
    table.insert(readData, data)
  end)
  outStream:on('error', function(err)
    table.insert(errData, err)
  end)
  outStream:once('end', function()
    cb(errData, readData)
  end)
end
-- End internals --

function exports.readStream(filePath)
  return readNormal(filePath)
end

function exports.readStreamClean(filePath)
  return readClean(filePath)
end

function exports.read(filePath, cb)
  readCb(filePath, readNormal, cb)
end

function exports.readClean(filePath, cb)
  readCb(filePath, readClean, cb)
end
