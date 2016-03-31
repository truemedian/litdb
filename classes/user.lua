local core = require('core')

local User = core.Object:extend()

function User:initialize(data)

	self.id = data.id -- string
	self.email = data.email -- string, only for auth'd account
	self.avatar = data.avatar -- string
	self.verified = data.verified -- boolean, only for auth'd account
	self.username = data.username -- string
	self.discriminator = data.discriminator -- string
	
end

return User
