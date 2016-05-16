local classes = require('../classes')
local class = classes.new
local constants = require('../constants')

local api = require('./api')
local Socket = require('./Socket')
local structures = require('../structures')

local Client = class(classes.EventsBased)

function Client:__constructor (settings)
	self.settings =
	{
		socket =
		{
			autoReconnect = true,
			large_threshold = 250,
		},
		forceFetch = false,
	}
	self.users = classes.Cache()
	self.servers = classes.Cache()
	self.channels = classes.Cache()
	self:initHandlers()
	self.socket = Socket(self)
end

function Client:login (config)
	if not config or (not config.token and not (config.email and config.password)) then return end
	coroutine.wrap(
		function()
			self.socket.token = config.token
			if not self.socket.token then
				self.socket.token = api.request(
					{
						type = 'GET',
						path = constants.api.endPoints.LOGIN,
						data =
						{
							email = config.email,
							password = config.password,
						},
					}
				).token
			end
			self.socket:connect()
		end
	)()
end

-- Stats
function Client:setStats (config)
	if config.game or config.status then
		self.socket:send(
			{
				op = constants.OPcodes.STATUS_UPDATE,
				d =
				{
					idle_since = (((config.status == 0) and nil) or 1),
					game =
					{
						name = (config.game or self.user.game),
					},
				},
			}
		)
	end
	if config.username or config.avatar then
		api.request(
			{
				type = 'PATCH',
				path = constants.api.endPoints.USERS_ME,
				token = self.socket.token,
				data = config,
			}
		)
	end
end
function Client:setStatus (status)
	self:setStats({status = status})
end
function Client:setUsername (username)
	self:setStats({username = username})
end
function Client:setAvatar (avatar)
	self:setStats({avatar = avatar})
end
function Client:setGame (game)
	self:setStats({game = game})
end

-- Invites
function Client:acceptInvite (code)
	api.request(
		{
			type = 'POST',
			path = 'invites/'..code,
			token = self.socket.token,
		}
	)
end

-- Creating guilds
function Client:getRegions ()
	return api.request(
		{
			type = 'GET',
			path = constants.api.endPoints.VOICE_REGIONS,
		}
	)
end
function Client:createServer ()
	local data = api.request(
		{
			type = 'POST',
			path = constants.api.endPoints.GUILDS,
			token = self.socket.token,
		}
	)
	local server = structures.Server(self)
	self.servers:add(server)
	server:update(data)
	return server
end

-- Sending messages
function Client:sendMessage (channel, content, options)
	local channelID = channel
	if type(channel) == 'table' then
		channelID = channel.id
	end
	options = options or {}
	options.content = content
	return api.request(
		{
			type = 'POST',
			path = 'channels/'..channelID..'/messages',
			token = self.socket.token,
			data = options,
		}
	)
end

-- Removing bans
function Client:unbanUser (server, user)
	local serverID = server
	if type(server) == 'table' then
		serverID = server.id
	end
	local userID = user
	if type(user) == 'table' then
		userID = user.id
	end
	api.request(
		{
			type = 'DELETE',
			path = 'guild/'..serverID..'/bans/'..userID,
			token = self.socket.token,
		}
	)
end

-- Core events
function Client:initHandlers ()
	self:on(
		constants.events.READY,
		function(data)
			local user = structures.User(self)
			user:update(data.user)
			self.users:add(user)
			self.user = user
		end
	)
	------------------------------------------------------------------------
	-- Message
	self:on(
		constants.events.MESSAGE_CREATE,
		function(data)
			local user = structures.User(self)
			user:update(data.author)
			self.users:add(user) -- will fail if already exists, intended
			local message = structures.Message(self)
			message:update(data)
			self:dispatchEvent('message', message)
		end
	)
	self:on( -- may not contain full data
		constants.events.MESSAGE_UPDATE,
		function(data)
			local message = structures.Message(self)
			message:update(data)
			self:dispatchEvent('messageUpdate', message)
		end
	)
	------------------------------------------------------------------------
	-- Users
	local function user_update(data)
		local user = self.users:get('id', data.id)
		if data.status == 'offline' then
			if user then
				self.users:remove(user)
			end
			return
		end
		if not user then
			user = structures.User(self)
			self.users:add(user)
		end
		user:update(data)
		return user
	end
	self:on(constants.events.PRESENCE_UPDATE, user_update)
	------------------------------------------------------------------------
	-- Servers (guilds)
	local function guild_update(data)
		data.roles = nil
		data.members = nil
		data.channels = nil
		--
		local server = self.servers:get('id', data.id)
		if not server then
			server = structures.Server(self)
			self.servers:add(server)
		end
		server:update(data)
		return server
	end
	self:on(
		constants.events.GUILD_CREATE,
		function(data)
			local roles = data.roles
			local members = data.members
			local channels = data.channels
			--
			local server = guild_update(data)
			if not server then return end
			-- Members
			if not members then
				self.socket:send(
					{
						op = constants.OPcodes.REQUEST_GUILD_MEMBERS,
						d =
						{
							guild_id = data.id,
							query = '',
							limit = 0,
						}
					}
				)
			else
				self:dispatchEvent(
					constants.events.GUILD_MEMBERS_CHUNK,
					{
						guild_id = data.id,
						members = members,
					}
				)
			end
			-- Channels
			if channels then
				for _,v in ipairs(channels) do
					v.guild_id = data.id
					self:dispatchEvent(constants.events.CHANNEL_CREATE, v)
				end
			end
			-- Roles
			if roles then
				for _,v in ipairs(roles) do
					self:dispatchEvent(
						constants.events.GUILD_ROLE_CREATE,
						{
							guild_id = data.id,
							role = v,
						}
					)
				end
			end
		end
	)
	self:on(constants.events.GUILD_UPDATE, guild_update)
	self:on(
		constants.events.GUILD_DELETE,
		function(data)
			self.servers:remove(data)
		end
	)
	-- Members
	self:on(
		constants.events.GUILD_MEMBERS_CHUNK,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			for _,v in ipairs(data.members) do
				local user = user_update(v.user)
				local member = structures.ServerMember(server)
				member:update(v)
				server.members:add(member)
			end
		end
	)
	self:on(
		constants.events.GUILD_MEMBER_REMOVE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			server.members:remove(data.user)
		end
	)
	-- Roles
	local function role_update(data)
		local server = self.servers:get('id', data.guild_id)
		if not server then return end
		local role = server.roles:get('id', data.role.id)
		if not role then
			role = structures.Role(self)
			server.roles:add(role)
		end
		role:update(data.role)
	end
	self:on(constants.events.GUILD_ROLE_CREATE, role_update)
	self:on(constants.events.GUILD_ROLE_UPDATE, role_update)
	self:on(
		constants.events.GUILD_ROLE_DELETE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			server.roles:remove(data.role)
		end
	)
	------------------------------------------------------------------------
	-- Channels
	local function channel_update(data)
		local server = self.servers:get('id', data.guild_id)
		if not data.is_private and not server then return end
		local channel = self.channels:get('id', data.id)
		if not channel then
			channel = structures.Channel(self)
			self.channels:add(channel)
		end
		channel:update(data)
		if not data.is_private then
			server.channels:add(channel)
		end
	end
	self:on(constants.events.CHANNEL_CREATE, channel_update)
	self:on(constants.events.CHANNEL_UPDATE, channel_update) -- guild channels only (?)
	self:on(
		constants.events.CHANNEL_DELETE,
		function(data)
			self.channels:remove(data)
		end
	)
	------------------------------------------------------------------------
	self.initHandlers = nil
end

return Client