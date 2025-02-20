local class = require('class')

local AbstractDecoder = class('AbstractDecoder')

function AbstractDecoder:__init() end

function AbstractDecoder:getTrack()
  error('Missing :getTrack() function')
end

function AbstractDecoder:changeBytes(bytes)
  self._position = self._position + bytes
  return self._position - bytes
end

function AbstractDecoder:readByte()
  local byte = self:changeBytes(1)
  return self._buffer[byte]
end

function AbstractDecoder:readUnsignedShort()
  local byte = self:changeBytes(2)
  return self._buffer:readUInt16BE(byte)
end

function AbstractDecoder:readInt()
  local byte = self:changeBytes(4)
  return self._buffer:readInt32BE(byte)
end

function AbstractDecoder:readLong()
  local msb = self:readInt()
  local lsb =  self:readInt()

  return msb * (2 ^ 32) + lsb
end

function AbstractDecoder:readUTF()
  local len = self:readUnsignedShort()
  local start = self:changeBytes(len)
  local result = self._buffer:toString(start, start + len - 1)
  return result
end


return AbstractDecoder