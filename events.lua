local timer = require('timer')

local User = require('./classes/user')
local Role = require('./classes/role')
local Server = require('./classes/server')
local Channel = require('./classes/channel')
local Message = require('./classes/message')
local VoiceState = require('./classes/voicestate')
local PrivateChannel = require('./classes/privatechannel')

local events = {}

function events.ready(data, client)

	client.user = User:new(data.user, client) -- object
	client.users[client.user.id] = client.user
	client.sessionId = data.sessionId -- string
	client.heartbeatInterval = data.heartbeatInterval -- number
	-- client.readState = data.readState -- table, status in each channel
	-- client.userServerSettings = data.userGuildSettings -- table, settings per server
	-- client.userSettings = data.userSettings -- table, personal user settings

	for _, friendData in ipairs(data.relationships) do
		local user = client:getUserById(friendData.user.id)
		if not user then
			user = User:new(friendData, client)
			client.users[user.id] = user
		else
			user:update(friendData)
		end
		client.friends[user.id] = user
	end

	for _, friendData in ipairs(data.presences) do
		local user = client:getUserById(friendData.user.id)
		user:update(friendData)
	end

	for _, serverData in ipairs(data.guilds) do
		local server = Server:new(serverData, client)
		client.servers[server.id] = server
	end

	for _, privateChannelData in ipairs(data.privateChannels) do
		local privateChannel = PrivateChannel:new(privateChannelData, client)
		client.privateChannels[privateChannel.id] = privateChannel
	end

	coroutine.wrap(function()
		while true do
			timer.sleep(client.heartbeatInterval)
			client.ws:send({op = 1, d = os.time()})
		end
	end)()

	client:emit('ready')

end

function events.typingStart(data, client)

	local channel = client:getChannelById(data.channelId)
	local user = client:getUserById(data.userId)
	client:emit('typingStart', channel, user)

end

function events.presenceUpdate(data, client)

	local user = client:getUserById(data.user.id)
	if not user then return end -- invalid user, probably large server
	local server = client:getServerById(data.guildId)
	user:update(data, server)
	client:emit('presenceUpdate', user)

end

function events.userUpdate(data, client)

	client.user:update(data, client)
	client:emit('userUpdate', client.user)

end

function events.voiceStateUpdate(data, client)

	local server = client:getServerById(data.guildId)
	local voiceState = server.voiceStates[data.sessionId]

	if not voiceState then
		voiceState = VoiceState:new(data, server)
		server.voiceStates[voiceState.sessionId] = voiceState
		client:emit('voiceJoin', voiceState)
	elseif voiceState.channelId then
		voiceState:update(data)
		client:emit('voiceUpdate', voiceState)
	else
		server.voiceStates[voiceState.sessionId] = nil
		client:emit('voiceLeave', voiceState)
	end

end

function events.messageCreate(data, client)

	local channel = client:getChannelById(data.channelId)
	local message = Message:new(data, channel)
	channel.messages[message.id] = message
	channel.deque:pushRight(message)
	if channel.deque:size() > client.maxMessages then
		local msg = channel.deque:popLeft()
		channel.messages[msg.id] = nil
	end
	client:emit('messageCreate', message)

end

function events.messageDelete(data, client)

	local message = client:getMessageById(data.id)
	if message then message.channel.messages[message.id] = nil end
	-- deleted messages stay in the deque and contribute to total count
	client:emit('messageDelete', message)

end

function events.messageUpdate(data, client)

	local message = client:getMessageById(data.id)

	if not message then
		local channel = client:getChannelById(data.channelId)
		message = Message:new(data, channel)
		channel.messages[message.id] = message
	else
		message:update(data)
	end

	client:emit('messageUpdate', message)

end

function events.messageAck(data, client)

	local channel = client:getChannelById(data.channelId)
	local message = channel:getMessageById(data.messageId)
	client:emit('messageAcknowledge', channel, message)

end

function events.channelCreate(data, client)

	local server = client:getServerById(data.guildId)

	if data.isPrivate then
		local privateChannel = PrivateChannel:new(data, client)
		client.privateChannels[privateChannel.id] = privateChannel
		client:emit('channelCreate', privateChannel)
	else
		local channel = Channel:new(data, server)
		server.channels[channel.id] = channel
		client:emit('channelCreate', channel)
	end

end

function events.channelDelete(data, client)

	local server = client:getServerById(data.guildId)
	local channel = server:getChannelById(data.id)
	server.channels[channel.id] = nil
	client:emit('channelDelete', channel)

end

function events.channelUpdate(data, client)

	local server = client:getServerById(data.guildId)
	local channel = client:getChannelById(data.guildId)

	if not channel then
		channel = Channel:new(data, server)
		server.channels[channel.id] = channel
	else
		channel:update(data)
	end

	client:emit('channelUpdate', channel)

end

function events.guildBanAdd(data, client)

	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	client:emit('memberBan', member, server)

end

function events.guildBanRemove(data, client)

	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	client:emit('memberUnban', member, server)

end

function events.guildCreate(data, client)

	if data.unavailable then return end
	local server = Server:new(data, client)
	client.servers[server.id] = server
	client:emit('serverCreate', server)

end

function events.guildDelete(data, client)

	if data.unavailable then return end
	local server = client:getServerById(data.id)
	client.servers[server.id] = nil
	client:emit('serverDelete', server)

end

function events.guildUpdate(data, client)

	local server = client:getServerById(data.id)
	server:update(data)
	client:emit('server.Update', server)

end

function events.guildIntegrationsUpdate(data, client)
end

function events.guildMemberAdd(data, client)

	local user = client:getUserById(data.user.id)
	local server = client:getServerById(data.guildId)
	if not user then
		user = User:new(data, server)
		client.users[user.id] = user
	else
		user:update(data, server)
	end
	server.members[user.id] = user

	client:emit('memberJoin', user, server)

end

function events.guildMemberRemove(data, client)

	local user = client:getUserById(data.user.id)
	local server = client:getServerById(data.guildId)
	server.members[user.id] = nil
	user.memberData[server.id] = nil
	client:emit('memberLeave', user, server)

end

function events.guildMemberUpdate(data, client)

	local user = client:getUserById(data.user.id)
	local server = client:getServerById(data.guildId)
	user:update(data, server)
	client:emit('memberUpdate', user, server)

end

function events.guildMembersChunk(data, client)

	local server = client:getServerById(data.guildId)

	for _, memberData in ipairs(data.members) do
		local user = client:getUserById(memberData.user.id)
		if not user then
			user = User:new(memberData, server)
			client.users[user.id] = user
		else
			user:update(memberData, server)
		end
		server.members[user.id] = user
	end

	client:emit('membersChunk', server)

end

function events.guildRoleCreate(data, client)

	local server = client:getServerById(data.guildId)
	local role = Role:new(data.role, server)
	server.roles[role.id] = role
	client:emit('roleCreate', role, server)

end

function events.guildRoleDelete(data, client)

	local server = client:getServerById(data.guildId)
	local role = server:getRoleById(data.roleId)
	server.roles[role.id] = nil
	client:emit('roleDelete', role, server)

end

function events.guildRoleUpdate(data, client)

	local server = client:getServerById(data.guildId)
	local role = server:getRoleById(data.role.id)
	role:update(data)
	client:emit('roleUpdate', role, server)

end

return events
