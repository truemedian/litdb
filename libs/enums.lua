-- Get from https://github.com/SinisterRectus/Discordia/blob/master/libs/enums.lua

local function enum(tbl)
	local call = {}
	for k, v in pairs(tbl) do
		if call[v] then
			return error(string.format('enum clash for %q and %q', k, call[v]))
		end
		call[v] = k
	end
	return setmetatable({}, {
		__call = function(_, k)
			if call[k] then
				return call[k]
			else
				return error('invalid enumeration: ' .. tostring(k))
			end
		end,
		__index = function(_, k)
			if tbl[k] then
				return tbl[k]
			else
				return error('invalid enumeration: ' .. tostring(k))
			end
		end,
		__pairs = function()
			return next, tbl
		end,
		__newindex = function()
			return error('cannot overwrite enumeration')
		end,
	})
end

local enums = {enum = enum}

enums.PluginType = enum {
  Default = 'default',
  SourceResolver = 'sourceResolver',
}

enums.PlayerState = enum {
  CONNECTED = 0,
  DISCONNECTED = 1,
  DESTROYED = 2,
}

enums.LoopMode = enum {
  SONG = 'song',
  QUEUE = 'queue',
  NONE = 'none',
}

enums.ConnectState = enum {
  Connected = 0,
  Disconnected = 1,
  Closed = 2,
}

enums.VoiceState = enum {
  SESSION_READY = 0,
  SESSION_ID_MISSING = 1,
  SESSION_ENDPOINT_MISSING = 2,
  SESSION_FAILED_UPDATE = 3,
}

enums.VoiceConnectState = enum {
  CONNECTING = 0,
  NEARLY = 1,
  CONNECTED = 2,
  RECONNECTING = 3,
  DISCONNECTING = 4,
  DISCONNECTED = 5,
}

enums.LavalinkLoadType = enum {
  TRACK = 'track',
  PLAYLIST = 'playlist',
  SEARCH = 'search',
  EMPTY = 'empty',
  ERROR = 'error',
}

enums.SearchResultType = enum {
  TRACK = 'TRACK',
  PLAYLIST = 'PLAYLIST',
  SEARCH = 'SEARCH',
}
enums.LavalinkEventsEnum = enum {
  Ready = 'ready',
  Status = 'stats',
  Event = 'event',
  PlayerUpdate = 'playerUpdate',
}

enums.LavalinkPlayerEventsEnum = enum {
  TrackStartEvent = 'TrackStartEvent',
  TrackEndEvent = 'TrackEndEvent',
  TrackExceptionEvent = 'TrackExceptionEvent',
  TrackStuckEvent = 'TrackStuckEvent',
  WebSocketClosedEvent = 'WebSocketClosedEvent',
}


return enums