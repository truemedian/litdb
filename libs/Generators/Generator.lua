local Object = require("core").Object

local Generator = Object:extend()

function Generator:initialize(Statements)
	self.Statements = Statements
	self.Position = 1
end

function Generator:Peek()
	return self.Statements[self.Position]
end

function Generator:Next()
	self.Position = self.Position + 1
	return self.Statements[self.Position-1]
end

return Generator