local timer = require('timer')

local User = require('./classes/user')
local Server = require('./classes/server')
local Friend = require('./classes/friend')
local Message = require('./classes/message')
local VoiceState = require('./classes/voicestate')

local events = {}

function events.ready(client, data)
		
	client.user = User:new(data.user) -- table -> object
	client.sessionId = data.sessionId -- string
	client.heartbeatInterval = data.heartbeatInterval -- number
	
	client.servers = {} -- guilds
	client.friends = {} -- relationships
	
	for _, serverData in ipairs(data.guilds) do
		local server = Server:new(serverData)
		client.servers[server.id] = server
	end
	
	for _, friendData in ipairs(data.relationships) do
		local friend = Friend:new(friendData)
		client.friends[friend.id] = friend
	end
	
	for _, friendData in ipairs(data.presences) do
		local friend = client.friends[friendData.user.id]
		friend:update(friendData)
	end
	
	-- client.readState = data.readState -- table, status in each channel
	-- client.privateChannels = data.privateChannels -- table, direct messages
	-- client.userServerSettings = data.userGuildSettings -- table, settings per server
	-- client.userSettings = data.userSettings -- table, personal user settings

	coroutine.wrap(function()
		while true do
			timer.sleep(client.heartbeatInterval)
			client.ws:send({op = 1, d = os.time()})
		end
	end)()
	
	client:emit('ready')

end
	
function events.typingStart(client, data)
	-- client:emit('typingStart', data)
end
	
function events.presenceUpdate(client, data)
	-- client:emit('presenceUpdate', data)
end
	
function events.userSettingsUpdate(client, data)
	-- client:emit('userSettingsUpdate', data)
end
	
function events.voiceStateUpdate(client, data)

	local server = client.servers[data.guildId]
	local voiceState = server.voiceStates[data.sessionId]

	if not voiceState then
		voiceState = VoiceState:new(data)
		server.voiceStates[data.sessionId] = voiceState
		client:emit('userJoinVoiceChannel', voiceState)
	elseif voiceState.channelId then
		voiceState:update(data)
		client:emit('userVoiceStateChange', voiceState)
	else
		server.voiceStates[data.sessionId] = nil
		client:emit('userLeaveVoiceChannel', voiceSate)
	end

end
	
function events.messageCreate(client, data)
	
	local channel = client:getChannelById(data.channelId)
	
	local message = Message:new(data, channel)
	channel.messages[message.id] = message

	client:emit('messageCreate', message)
	
end
	
function events.messageDelete(client, data)
end
	
function events.messageUpdate(client, data)
end
	
function events.channelCreate(client, data)
end
	
function events.channelDelete(client, data)
end
	
function events.channelUpdate(client, data)
end
	
function events.guildBanAdd(client, data)
end
	
function events.guildBanRemove(client, data)
end
	
function events.guildCreate(client, data)
end
	
function events.guildDelete(client, data)
end
	
function events.guildUpdate(client, data)
end
	
function events.guildIntegrationsUpdate(client, data)
end
	
function events.guildMemberAdd(client, data)
end
	
function events.guildMemberRemove(client, data)
end
	
function events.guildMemberUpdate(client, data)
end
	
function events.guildRoleCreate(client, data)
end
	
function events.guildRoleDelete(client, data)
end
	
function events.guildRoleUpdate(client, data)
end

return events
