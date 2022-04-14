--[=[ 
    Variables that determine the endpoint from which to take the information.
    Example:
        http.request("GET", "https://discord.com/api/v10/" + string.format(USER, "_userId_", headers)
]=]
return {
	CHANNEL_MESSAGE     = "/channels/%s/messages/%s",
	CHANNEL_MESSAGES    = "/channels/%s/messages",
	GUILD          		= "/guilds/%s",
	GUILDS         		= "/guilds",
	USER           		= "/users/%s",
	ME             		= "/users/@me",
	ME_CHANNELS    		= "/users/@me/channels",
	ME_CONNECTIONS 		= "/users/@me/connections",
	ME_GUILD       		= "/users/@me/guilds/%s",
	ME_GUILDS      		= "/users/@me/guilds",
}
