local User = require('./classes/user')
local Game = require('./classes/game')

local Friend = User:extend()

function Friend:initialize(data)

	local user = data.user
	
	self.id = user.id -- string
	self.type = data.type -- number, unique to friends (not members)
	self.avatar = user.avatar -- string
	self.username = user.username -- string
	self.discriminator = user.discriminator -- string
	
end

function Friend:update(data)

	local user = data.user

	self.type = user.type -- number
	self.status = data.status -- string
	self.avatar = user.avatar -- string
	self.username = user.username -- string
	self.lastModified = data.lastModified -- number

	if data.game then
		self.game = Game:new(data.game) -- object
	end

end

return Friend