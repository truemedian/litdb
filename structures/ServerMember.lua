local classes = require('../classes')
local class = classes.new
local base = require('./base')

local api = require('../client/api')

local ServerMember = class(base)

function ServerMember:onUpdate () -- parent = server / server.parent = client |=> .parent.parent equals to client
	self.id = self.user.id
	self.user = self.parent.parent.users:get('id', self.user.id)
	for i,v in ipairs(self.roles) do
		local role = self.parent.roles:get('id', v)
		table.insert(self.roles, i, role)
	end
end

function ServerMember:kick ()
	api.request(
		{
			type = 'DELETE',
			path = '/guilds/'..self.parent.id..'/members/'..self.user.id,
			token = self.parent.parent.socket.token,
		}
	)
end

function ServerMember:ban (days)
	api.request(
		{
			type = 'PUT',
			path = '/guilds/'..self.parent.id..'/bans/'..self.user.id,
			token = self.parent.parent.socket.token,
			data =
			{
				['delete-message-days'] = days or 0,
			},
		}
	)
end

return ServerMember