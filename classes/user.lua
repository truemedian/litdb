local endpoints = require('../endpoints')
local request = require('../utils').request

local User = require('core').Object:extend()

function User:initialize(data, parent)

	self.client = parent.client or parent

	self.messages = {}
	self.memberData = {}

	self.email = data.email or self.email -- clientUser only
	self.verified = data.verified or self.verified -- clientUser only

	local user = data.user or data.recipient or data.author

	self.id = data.id or user.id
	self.avatar = data.avatar or user and user.avatar or ''
	self.username = data.username or user.username
	self.discriminator = data.discriminator or user.discriminator

	self:update(data, parent)

end

function User:update(data, parent)

	self.status = data.status or self.status or 'offline'
	self.gameName = data.game and data.game.name or self.gameName
	self.lastModified = data.lastModified or self.lastModified
	self.isFriend = data.type == 1 or self.isFriend

	if data.joinedAt then -- server member
		self.memberData[parent.id] = {
			deaf = data.deaf,
			mute = data.mute,
			roles = data.roles,
			joinedAt = data.joinedAt
		}
	-- elseif data.recipient then -- private channel recipient
	-- 	-- self.privateChannel = parent
	-- elseif data.author then -- message author
	-- 	-- self.messages[parent.id] = parent
	end

end

return User
