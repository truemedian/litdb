local class = require('class')
local Events = require('const').Events
local SearchResultType = require('enums').SearchResultType
local f = string.format

---A class for managing track info
---@class Track
---<!tag:interface>
---@field encode string Encoded string from lavalink
---@field identifier string Identifier string from lavalink
---@field isSeekable boolean Whenever track is seekable or not
---@field author string Track's author
---@field duration number Track's duration
---@field isStream boolean Whenever track is stream able or not
---@field position number Track's position
---@field title string Track's title
---@field uri 'string/nil' Track's URL
---@field artworkUrl 'string/nil' Track's artwork URL
---@field isrc 'string/nil' Track's isrc
---@field source string Track's source name
---@field pluginInfo unknown Data from lavalink plugin
---@field requester unknown Track's requester
---@field realUri 'string/nil' Track's realUri (youtube fall back)
---@field driverName string Name of the driver that search this track
---@field raw RawTrack Get all raw details of the track
---@field isPlayable boolean Whenever track is able to play or not

local Track, get = class('LunalinkTrack')

---The rainlink track class for playing track from lavalink
---@param options RawTrack
---@param requester string
---@param driverName 'string/nil'
function Track:__init(options, requester, driverName)
  self._options      =   options
  self._encoded      =   options.encoded
  self._identifier   =   options.info.identifier
  self._isSeekable   =   options.info.isSeekable
  self._author       =   options.info.author
  self._duration     =   options.info.length
  self._isStream     =   options.info.isStream
  self._position     =   options.info.position
  self._title        =   options.info.title
  self._uri          =   options.info.uri
  self._artworkUrl   =   options.info.artworkUrl
  self._isrc         =   options.info.isrc
  self._source       =   options.info.sourceName
  self._pluginInfo   =   options.pluginInfo
  self._requester    =   requester
  self._realUri      =   nil
  self._driverName   =   driverName
end

function get:encoded()
  return self._encoded
end

function get:identifier()
  return self._identifier
end

function get:isSeekable()
  return self._isSeekable
end

function get:author()
  return self._author
end

function get:duration()
  return self._duration
end

function get:isStream()
  return self._isStream
end

function get:position()
  return self._position
end

function get:title()
  return self._title
end

function get:uri()
  return self._uri
end

function get:artworkUrl()
  return self._artworkUrl
end

function get:isrc()
  return self._isrc
end

function get:source()
  return self._source
end

function get:pluginInfo()
  return self._pluginInfo
end

function get:requester()
  return self._requester
end

function get:realUri()
  return self._realUri
end

function get:driverName()
  return self._driverName
end

function get:isPlayable()
  return (
    self._encoded and
    self._source and
    self._identifier and
    self._author and
    self._duration and
    self._title and
    self._uri
  )
end

function get:raw()
  return {
    encoded = self._encoded,
    info = {
      identifier = self._identifier,
      isSeekable = self._isSeekable,
      author = self._author,
      length = self._duration,
      isStream = self._isStream,
      position = self._position,
      title = self._title,
      uri = self._uri,
      artworkUrl = self._artworkUrl,
      isrc = self._isrc,
      sourceName = self._source,
    },
    pluginInfo = self._pluginInfo,
  }
end

function Track:resolver(player, options)
  options = options or {}
  local overwrite = options and options.overwrite or false

  if (self.isPlayable and self._driverName == player.node.driver.id) then
    self._realUri = self.raw.info.uri
    return self
  end

  player.manager.emit(
    Events.Debug,
    f(
      "[Lunalink] / [Track] | Resolving %s track %s; Source: %s",
      self._source,
      self._title,
      self._source
    )
  )

  local result = self:getTrack(player)
  assert(result, 'No results found')

  self._encoded = result.encoded
  self._realUri = result.info.uri
  self._duration = result.info.length

  if (overwrite) then
    self._title = result.info.title
    self._identifier = result.info.identifier
    self._isSeekable = result.info.isSeekable
    self._author = result.info.author
    self._duration = result.info.length
    self._isStream = result.info.isStream
    self._uri = result.info.uri
  end
  return self
end

function Track:getTrack(player)
  local result = self:resolverEngine(player)

  if not result or not result.tracks.length then error('No results found') end

  local rawTracks = self:_map(result.tracks, function (x)
    return x.raw
  end)

  if self._author then
    local author = { self.author, self.author .. " - Topic" }
    local officialTrack = self:_find(rawTracks, function (track)
      return self:_some(author, function (name)
        return string.match(self:escp(name), track.info.author)
      end) or string.match(self:escp(self._title), track.info.title)
    end)
    if officialTrack then return officialTrack end
  end

  if self._duration then
    local sameDuration = self:_find(rawTracks, function (track)
      return (track.info.length >= (self.duration and self.duration or 0) - 2000) and
             (track.info.length <= (self._duration and self._duration or 0) + 2000)
    end)
    if sameDuration then return sameDuration end
  end

  return rawTracks[1]
end

function Track:escp(str)
  return (str:gsub("([%.%^%$%(%)%[%]%%%*%+%-%?])", "%%%1"))
end

function Track:resolverEngine(player)
  local defaultSearchEngine = player._lunalink.options.config.defaultSearchEngine
  local engine = player._lunalink.searchEngines:get(self._source or defaultSearchEngine or 'youtube')
  local searchQuery = table.concat(self:_filter({ self._author, self._title }, function (x)
    return x
  end), ' - ')
  local searchFallbackEngineName = player._lunalink.options.config.searchFallback.engine
  local searchFallbackEngine = player._lunalink.searchEngines:get(searchFallbackEngineName)

  local prase1 = player:search(f("directSearch=%s", self._url), {
    requester = self._requester,
  })
  if prase1.tracks.length ~= 0 then return prase1 end

  local prase2 = player:search(f("directSearch=%ssearch:%s", engine, searchQuery), {
    requester = self._requester,
  })
  if prase2.tracks.length ~= 0 then return prase2 end

  if player._lunalink.options.config.searchFallback.enable and searchFallbackEngine then
    local prase3 = player:search(f("directSearch=%ssearch:%s", searchFallbackEngine, searchQuery),
      {
        requester = self._requester
      }
    )
    if prase3.tracks.length ~= 0 then return prase2 end
  end

  return {
    type = SearchResultType.SEARCH,
    playlistName = nil,
    tracks = {},
  }
end

function Track:_map(tbl, func)
	local result = {}
	for i, v in ipairs(tbl) do
			result[i] = func(v, i, tbl)
	end
	return result
end

function Track:_find(arr, condition)
  for _, value in ipairs(arr) do
    if condition(value) then
      return value
    end
  end
  return nil
end

function Track:_some(tbl, callback)
  for _, value in ipairs(tbl) do
    if callback(value) then
      return true
    end
  end
  return false
end

function Track:_filter(t, func)
	local out = {}
	for k, v in pairs(t) do
		if func(v, k, t) then
			table.insert(out, v)
		end
	end
	return out
end

return Track
