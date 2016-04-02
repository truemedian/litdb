local Role = require('core').Object:extend()

function Role:initialize(data, server)

	self.server = server

	self.id = data.id -- string
	self.hoist = data.hoist -- boolean
	self.permissions = data.permissions -- number
	self.color = data.color -- number
	self.name = data.name -- text
	self.managed = data.managed -- boolean
	self.position = data.position -- number

end

return Role
