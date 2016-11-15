local Snowflake = require('../Snowflake')

local insert = table.insert
local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Member, property, method, cache = class('Member', Snowflake)
Member.__description = "Represents a Discord guild member."

function Member:__init(data, parent)
	self._id = data.user.id
	Snowflake.__init(self, data, parent)
	local users = self._parent._parent._users
	self._user = users:get(data.user.id) or users:new(data.user)
	self:_update(data)
end

function Member:__tostring()
	if self._nick then
		return format('%s: %s (%s)', self.__name, self._user._username, self._nick)
	else
		return format('%s: %s', self.__name, self._user._username)
	end
end

function Member:_update(data)
	Snowflake._update(self, data)
	self._roles = data.roles -- raw table of IDs
end

function Member:_createPresence(data)
	self._status = data.status
	self._game = data.game
end

function Member:_updatePresence(data)
	self:_createPresence(data)
	self._user:_update(data.user)
end

local function setNick(self, nick)
	nick = nick or ''
	local guild = self._parent
	local client = guild._parent
	if self._user._id == client._user._id then
		return client:setNick(guild, nick)
	end
	local success = client._api:modifyGuildMember(guild._id, self._user._id, {nick = nick})
	if success then self._nick = nick end
	return success
end

local function setMute(self, mute)
	mute = mute or false
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {mute = mute})
	if success then self._mute = mute end
	return success
end

local function setDeaf(self, deaf)
	deaf = deaf or false
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {deaf = deaf})
	if success then self._deaf = deaf end
	return success
end

local function setVoiceChannel(self, channel)
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {channel_id = channel._id})
	return success
end

local function getStatus(self)
	return self._status or 'offline'
end

local function getGameName(self)
	return self._game and self._game.name
end

local function getName(self)
	return self._nick or self._user._username
end

-- User-compatability methods --

local function getMembership(self, guild)
	return self._user:getMembership(guild or self._parent)
end

local function sendMessage(self, ...)
	return self._user:sendMessage(...)
end

local function ban(self, guild, days)
	if not days and type(guild) == 'number' then
		days, guild = guild, self._parent
	end
	return self._user:ban(guild or self._parent, days)
end

local function unban(self, guild)
	return self._user:unban(guild or self._parent)
end

local function kick(self, guild)
	return self._user:kick(guild or self._parent)
end

local function _applyRoles(self, roles)
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {roles = roles})
	if success then self._roles = roles end
	return success
end

local function addRoles(self, ...)
	local role_ids = self._roles
	local guild_id = self._parent._id
	for i = 1, select('#', ...) do
		local role = select(i, ...)
		local id = role._id
		if id ~= guild_id then -- stop attempt to add @everyone
			insert(role_ids, id)
		end
	end
	return _applyRoles(self, role_ids)
end

local function removeRoles(self, ...)
	local removals = {}
	for i = 1, select('#', ...) do
		local role = select(i, ...)
		removals[role._id] = true
	end
	local role_ids = {}
	for _, id in ipairs(self._roles) do
		if not removals[id] then
			insert(role_ids, id)
		end
	end
	return _applyRoles(self, role_ids)
end

local function getRoleCount(self)
	return #self._roles
end

local function getRoles(self, key, value)
	local roles = self._parent._roles
	return wrap(function()
		for _, id in ipairs(self._roles) do
			local role = roles:get(id)
			if role[key] == value then
				yield(role)
			end
		end
	end)
end

local function getRole(self, key, value)
	local roles = self._parent._roles
	if key == nil and value == nil then return end
	if value == nil then
		value = key
		key = roles._key
	end
	for _, id in ipairs(self._roles) do
		local role = roles:get(id)
		if role[key] == value then return role end
	end
end

local function findRole(self, predicate)
	local roles = self._parent._roles
	for _, id in ipairs(self._roles) do
		local role = roles:get(id)
		if predicate(role) then return role end
	end
end

local function findRoles(self, predicate)
	return wrap(function()
		local roles = self._parent._roles
		for _, id in ipairs(self._roles) do
			local role = roles:get(id)
			if predicate(role) then yield(role) end
		end
	end)
end

property('avatarUrl', function(self) return self._user.avatarUrl end, nil, 'string', "Shortcut for member.user.avatarUrl")
property('defaultAvatarUrl', function(self) return self._user.defaultAvatarUrl end, nil, 'string', "Shortcut for member.user.defaultAvatarUrl")
property('mentionString', function(self) return self._user.mentionString end, nil, 'string', "Shortcut for member.user.mentionString")
property('id', function(self) return self._user._id end, nil, 'string', "Shortcut for member.user.id")
property('bot', function(self) return self._user._bot or false end, nil, 'string', "Shortcut for member.user.bot")
property('avatar', function(self) return self._user._avatar end, nil, 'string', "Shortcut for member.user.avatar")
property('defaultAvatar', function(self) return self._user.defaultAvatar end, nil, 'string', "Shortcut for member.user.defaultAvatar")
property('username', function(self) return self._user._username end, nil, 'string', "Shortcut for member.user.username")
property('discriminator', function(self) return self._user._discriminator end, nil, 'string', "Shortcut for member.user.discriminator")

property('status', getStatus, nil, 'string', "Whether the member is online, offline, or idle")
property('gameName', getGameName, nil, 'string', "Name of the game set in the member's status (can be nil if not set)")
property('name', getName, nil, 'string', "The member's nickname if one is set. Otherwise, its username.")
property('nickname', '_nick', setNick, 'string', "The member's nickname for the guild in which it exists (can be nil if not set)")
property('user', '_user', nil, 'User', "The base user associated with this member")
property('guild', '_parent', nil, 'Guild', "The guild in which this member exists")
property('joinedAt', '_joined_at', nil, 'string', "Date and time when the member joined the guild")

method('setMute', setMute, '[boolean]', "Mutes or unmutes the member guild-wide (default: false).")
method('setDeaf', setDeaf, '[boolean]', "Deafens or undeafens the member guild-wide (default: false).")
method('getMembership', getMembership, '[guild]', "Shortcut for `member.user:getMembership`")
method('sendMessage', sendMessage, 'content[, mentions, tts, nonce]', "Shortcut for `member.user:sendMessage`")
method('ban', ban, '[guild][, days]', "Shortcut for `member.user:ban`. The member's guild is used if none is provided.")
method('unban', unban, '[guild]', "Shortcut for `member.user:unban`. The member's guild is used if none is provided.")
method('kick', kick, '[guild]', "Shortcut for `member.user:kick`. The member's guild is used if none is provided.")
method('addRoles', addRoles, 'roles[, ...]', "Adds a role or roles to the member.")
method('removeRoles', removeRoles, 'roles[, ...]', "Removes a role or roles from the member.")
method('setVoiceChannel', setVoiceChannel, 'channel', "Moves a member to a voice channel if they are already in one.")

cache('Role', getRoleCount, getRole, getRoles, findRole, findRoles)

return Member
