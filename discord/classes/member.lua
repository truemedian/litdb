local User = require('./user')
local Game = require('./game')

local Member = User:extend()

function Member:initialize(data, server)
	
	self.server = server -- parent object
	
	local user = data.user
	
	self.id = user.id -- string
	self.avatar = user.avatar -- string
	self.username = user.username -- string
	self.discriminator = user.discriminator -- string
	
	self.deaf = data.deaf -- boolean
	self.mute = data.mute -- boolean
	self.joinedAt = data.joinedAt -- string
	
	self.roles = data.roles -- table of strings to link to server.roles
	
end

function Member:update(data)
	
	local user = data.user

	self.status = data.status -- string

	if data.game then
		self.game = Game:new(data.game) -- object
	end

end

return Member