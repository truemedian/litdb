local Object = require("core").Object

local Lexer = Object:extend()

function Lexer.from(otherLexer)
	local newLexer = Lexer:new()
	newLexer:Pull(otherLexer)
	return newLexer
end

function Lexer:initialize()
	self.Tokens = {}
end

function Lexer:Add(MatchString, Token)
	table.insert(self.Tokens, {
		MatchString = "^" .. MatchString,
		Token = Token,
	})
end

function Lexer:Keyword(MatchString, Token)
	self:Add("(" .. MatchString .. ")[^a-zA-Z0-9_]\0?", Token)
end

function Lexer:Match(String, Start)
	for i = 1, #self.Tokens do
		local Token = self.Tokens[i]
		local Match = String:match(Token.MatchString, Start)

		if Match and #Match > 0 then
			return Token.Token, Match
		end
	end

	if self.Extended then
		local Success, Token, Output = pcall(self.Extended.Match, self.Extended, String, Start)
		if Success then
			return Token, Output
		end
	end

	error("Expected token, got '" .. String:sub(Start, Start + 10) .. "...'")
end

function Lexer:Pull(otherLexer)
	for _, v in ipairs(otherLexer.Tokens) do
		table.insert(self.Tokens, v)
	end
end

return Lexer