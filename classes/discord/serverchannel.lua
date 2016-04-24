local Base = require('./base')
local Invite = require('./invite')
local endpoints = require('../../endpoints')

local ServerChannel = class('ServerChannel', Base)

function ServerChannel:__init(data, server)

	Base.__init(self, data.id, server.client)
	self.server = server

	self.type = data.type
	self:update(data)

end

function ServerChannel:createInvite()
	self.client:request('POST', {endpoints.channels, self.id, 'invites'}, {})
end

function ServerChannel:getInvites()
	local inviteTable = self.client:request('GET', {endpoints.channels, self.id, 'invites'})
	local invites = {}
	for _, inviteData in ipairs(inviteTable) do
		local invite = Invite(inviteData, self.server)
		invites[invite.id] = invite
	end
	return invites
end

function ServerChannel:update(data)
	self.name = data.name
	self.topic = data.topic
	self.position = data.position
	self.permissionOverwrites = data.permissionOverwrites
end

function ServerChannel:delete(data)
	self.client:request('DELETE', {endpoints.channels, self.id})
end

return ServerChannel
