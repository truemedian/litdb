return
{
	status = {
		IDLE = 3,
		CONNECTED = 0,
		CONNECTING = 1,
		RECONNECTING = 2,
	},
	OPcodes = {
		DISPATCH = 0,
		HEARTBEAT = 1,
		IDENTIFY = 2,
		STATUS_UPDATE = 3,
		VOICE_STATE_UPDATE = 4,
		VOICE_GUILD_PING = 5,
		RESUME = 6,
		RECONNECT = 7,
		REQUEST_GUILD_MEMBERS = 8,
		INVALID_SESSION = 9,
		HELLO = 10,
	}
}