local core = require('core')

local Game = core.Object:extend()

function Game:initialize(data)

	self.name = data.name

end

return Game
