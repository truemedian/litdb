local class = require('class')
local openssl = require('openssl')
local Buffer = require('buffer').Buffer
local AbstractDecoder = require('decoder/AbstractDecoder')

local LavalinkDecoder = class('LavalinkDecoder', AbstractDecoder)

function LavalinkDecoder:__init(track)
  AbstractDecoder.__init(self)
  self._position = 1
  self._track = track
  self._buffer = Buffer:new(openssl.base64(self._track, false))
end

function LavalinkDecoder:getTrack()
  local success, result = pcall(LavalinkDecoder.getTrackUnsafe, self)
  if not success then return nil end
  return result
end

function LavalinkDecoder:getTrackUnsafe()
  local isVersioned = bit.band(bit.rshift(self:readInt(), 30), 1) ~= 0
  local version = isVersioned and self:readByte() or 1
  if version == 1 then
    return self:trackVersionOne()
  elseif version == 2 then
    return self:trackVersionTwo()
  elseif version == 3 then
    return self:trackVersionThree()
  else
    return nil
  end
end

function LavalinkDecoder:trackVersionOne()
  local success, result = pcall(function ()
    return {
      encoded = self._track,
      info = {
        title = self:readUTF(),
        author = self:readUTF(),
        length = self:readLong(),
        identifier = self:readUTF(),
        isSeekable = true,
        isStream = self:readByte() ~= 0,
        uri = nil,
        artworkUrl = nil,
        isrc = nil,
        sourceName =  string.lower(self:readUTF()),
        position = self:readLong(),
      },
      pluginInfo = {},
    }
  end)

  if not success then return nil end
  return result
end

function LavalinkDecoder:trackVersionTwo()
  local success, result = pcall(function ()
    return {
      encoded = self._track,
      info = {
        title = self:readUTF(),
        author = self:readUTF(),
        length = self:readLong(),
        identifier = self:readUTF(),
        isSeekable = true,
        isStream = self:readByte() ~= 0,
        uri = self:readByte() and self:readUTF() or nil,
        artworkUrl = nil,
        isrc = nil,
        sourceName =  string.lower(self:readUTF()),
        position = self:readLong(),
      },
      pluginInfo = {},
    }
  end)

  if not success then return nil end
  return result
end

function LavalinkDecoder:trackVersionThree()
  local success, result = pcall(function ()
    return {
      encoded = self._track,
      info = {
        title = self:readUTF(),
        author = self:readUTF(),
        length = self:readLong(),
        identifier = self:readUTF(),
        isSeekable = true,
        isStream = self:readByte() ~= 0,
        uri = self:readByte() ~= 0 and self:readUTF() or nil,
        artworkUrl = self:readByte() ~= 0 and self:readUTF() or nil,
        isrc = self:readByte() ~= 0 and self:readUTF() or nil,
        sourceName =  string.lower(self:readUTF()),
        position = self:readLong(),
      },
      pluginInfo = {},
    }
  end)

  if not success then return nil end
  return result
end

return LavalinkDecoder