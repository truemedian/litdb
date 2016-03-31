local core = require('core')

local Role = require('./role')
local Member = require('./member')
local Channel = require('./channel')
local VoiceState = require('./voicestate')

local Server = core.Object:extend()

function Server:initialize(data, client)

	self.id = data.id -- string
	self.name = data.name -- string
	self.icon = data.icon -- string
	self.large = data.large -- boolean
	self.region = data.region -- string
	self.ownerId = data.ownerId -- string
	self.joinedAt = data.joinedAt -- string
	self.afkTimeout = data.afkTimeout -- number
	self.memberCount = data.memberCount -- number
	self.afkChannelId = data.afkChannelId -- string
	self.verificationLevel = data.verificationLevel -- number

	self.emojis = data.emojis -- table, not sure what to do with this
	self.features = data.features -- table, not sure what to do with this

	self.roles = {}
	self.members = {}
	self.channels = {}
	self.voiceStates = {} -- might store these on Member object
	
	for _, roleData in ipairs(data.roles) do
		local role = Role:new(roleData, self)
		self.roles[role.id] = role
	end

	for _, memberData in ipairs(data.members) do
		local member = Member:new(memberData, self)
		self.members[member.id] = member
	end
	
	for _, memberData in ipairs(data.presences) do
		local member = self.members[memberData.user.id]
		member:update(memberData)
	end
	
	for _, channelData in ipairs(data.channels) do
		local channel = Channel:new(channelData, self)
		self.channels[channel.id] = channel
	end
	
	for _, voiceData in ipairs(data.voiceStates) do
		local voiceState = VoiceState:new(voiceData, self)
		self.voiceStates[voiceState.userId] = voiceState
	end

end

return Server
