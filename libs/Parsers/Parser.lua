local Object = require("core").Object

local Parser = Object:extend()

function Parser:initialize(TokenList)
	self.TokenList = TokenList
end

function Parser:Symbol(...)
	local Symbols = { ... }

	for _, v in ipairs(Symbols) do
		if self.TokenList:Peek().Token == v then
			return self.TokenList:Next()
		end
	end

	if #Symbols == 1 then
		error("Expected " .. Symbols[1] .. " but got " .. self.TokenList:Peek().Token .. " (" .. self.TokenList:Peek().Value .. ") at " .. self.TokenList:Peek().Location)
	else
		error("Expected one of " .. table.concat(Symbols, ", ") .. " but got " .. self.TokenList:Peek().Token .. " (" .. self.TokenList:Peek().Value .. ") at " .. self.TokenList:Peek().Location)
	end
end

function Parser:Peek()
	return self.TokenList:Peek()
end

function Parser:Next(...)
	if self.TokenList:Peek() == nil then
		return false
	end

	for _, v in ipairs({...}) do
		if self.TokenList:Peek().Token == v then
			return true
		end
	end

	return false
end

function Parser:Consume()
	return self.TokenList:Next()
end

function Parser:KeepGoing(Function, ...)
	local OldPosition = self.TokenList.Position
	local Returns = { pcall(Function, self, ...) }

	if table.remove(Returns, 1) then
		return unpack(Returns)
	else
		self.TokenList.Position = OldPosition
		return
	end
end

return Parser