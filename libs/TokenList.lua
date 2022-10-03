local Object = require("core").Object

local TokenList = Object:extend()

function TokenList:initialize(String, Lexer)
	self.Source = String .. "\n"

	local Position, Line, Col = 1, 1, 0
	local Tokens = {}

	while Position <= #self.Source do
		local Token, Output = Lexer:Match(self.Source, Position)

		table.insert(Tokens, {
			Start = Position,
			End = Position + #Output,
			Token = Token,
			Value = Output,
			Location = ("%d:%d"):format(Line, Col),
		})

		Position = Position + #Output

		if Output:match("\n") then
			Line = Line + 1
			Col = 0
		else
			Col = Col + #Output
		end
	end

	self.Tokens = {}
	local LeadingTrivia, TrailingTrivia = {}, {}
	while Tokens[1] do
		local Token = table.remove(Tokens, 1)

		if Token.Token == "Whitespace" or Token.Token == "Comment" then
			table.insert(LeadingTrivia, Token)
		else
			while Tokens[1] ~= nil do
				if Tokens[1].Token ~= "Whitespace" and Tokens[1].Token ~= "Comment" then
					break
				end

				local TrailingToken = table.remove(Tokens, 1)
				table.insert(TrailingTrivia, TrailingToken)

				if TrailingToken.Value:match("\n") then
					break
				end
			end

			Token.LeadingTrivia = LeadingTrivia
			Token.TrailingTrivia = TrailingTrivia

			table.insert(self.Tokens, Token)

			LeadingTrivia, TrailingTrivia = {}, {}
		end
	end

	self.Position = 1
end

function TokenList:Peek()
	return self.Tokens[self.Position]
end

function TokenList:Next()
	self.Position = self.Position + 1
	return self.Tokens[self.Position - 1]
end

return TokenList