local libraries = {
    ["Windows-x64"] = "discord-rpc.dll",
    ["Windows-x86"] = "discord-rpc.dll",
    ["Linux-x64"] = "libdiscord-rpc.so",
    ["OSX-x64"] = "libdiscord-rpc.dylib",
}

local ffi = require('ffi')
local arch = ffi.os .. '-' .. ffi.arch
local dlib = ffi.load('libs/'..arch..'/'..libraries[arch])

ffi.cdef[[
typedef struct DiscordRichPresence {
    const char* state;   /* max 128 bytes */
    const char* details; /* max 128 bytes */
    int64_t startTimestamp;
    int64_t endTimestamp;
    const char* largeImageKey;  /* max 32 bytes */
    const char* largeImageText; /* max 128 bytes */
    const char* smallImageKey;  /* max 32 bytes */
    const char* smallImageText; /* max 128 bytes */
    const char* partyId;        /* max 128 bytes */
    int partySize;
    int partyMax;
    const char* matchSecret;    /* max 128 bytes */
    const char* joinSecret;     /* max 128 bytes */
    const char* spectateSecret; /* max 128 bytes */
    int8_t instance;
} DiscordRichPresence;
typedef struct DiscordUser {
    const char* userId;
    const char* username;
    const char* discriminator;
    const char* avatar;
} DiscordUser;
typedef void (*readyPtr)(const DiscordUser* request);
typedef void (*disconnectedPtr)(int errorCode, const char* message);
typedef void (*erroredPtr)(int errorCode, const char* message);
typedef struct DEventHandler {
    readyPtr ready;
    disconnectedPtr disconnected;
    erroredPtr errored;
} DEventHandler;
void Discord_Initialize(const char* applicationId,
                        DEventHandler* handlers,
                        int autoRegister,
                        const char* optionalSteamId);
void Discord_Shutdown(void);
void Discord_UpdatePresence(const DiscordRichPresence* presence);
]]
local function du(request)
    return ffi.string(request.userId), ffi.string(request.username),
        ffi.string(request.discriminator), ffi.string(request.avatar)
end
local ep = ffi.cast("erroredPtr", function(errorCode, message)
    if exports.errored then
        exports.errored(errorCode, ffi.string(message))
    end
end)
local dp = ffi.cast("disconnectedPtr", function(errorCode, message)
    if exports.disconnected then
        exports.disconnected(errorCode, ffi.string(message))
	dis = 'yes'
    end
end)
local rp = ffi.cast("readyPtr", function(request)
    if exports.ready then
        exports.ready(du(request))
	init = 'yes'
    end
end)

function exports.initialize(applicationId, autoRegister, optionalSteamId)
    local eventHandlers = ffi.new("struct DEventHandler")
    eventHandlers.ready = rp
    eventHandlers.disconnected = dp
    eventHandlers.errored = ep
    dlib.Discord_Initialize(applicationId, eventHandlers, autoRegister and 1 or 0, optionalSteamId)
end

function exports.isRunning()
    if init == 'yes' then
	return true
    else
	return false
    end
end

function exports.isDisconnected()
    if dis == 'yes' then
	return true
    else
	return false
    end
end

function exports.shutdown()
    dlib.Discord_Shutdown()
end

function exports.updatePresence(presence)
    local cp = ffi.new("struct DiscordRichPresence")
    cp.state = presence.state
    cp.details = presence.details
    cp.startTimestamp = presence.startTimestamp or 0
    cp.endTimestamp = presence.endTimestamp or 0
    cp.largeImageKey = presence.largeImageKey
    cp.largeImageText = presence.largeImageText
    cp.smallImageKey = presence.smallImageKey
    cp.smallImageText = presence.smallImageText
    cp.instance = presence.instance or 0
    dlib.Discord_UpdatePresence(cp)
end

exports.D = newproxy(true)
getmetatable(exports.D).__gc = function() 
    exports.shutdown() rp:free() dp:free() ep:free()
end
