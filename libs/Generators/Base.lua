local Generator = require("Generators/Generator")
local BaseNodes = require("Nodes/Base")

local Base = Generator:extend()

function Base:Generate()
	local Output = ""

	while self:Peek() do
		Output = Output .. self:Statement(self:Next())
	end

	return Output
end

function Base:Token(Token)
	local Output = ""

	for _, v in ipairs(Token.LeadingTrivia) do
		Output = Output .. v.Value
	end

	Output = Output .. Token.Value

	for _, v in ipairs(Token.TrailingTrivia) do
		Output = Output .. v.Value
	end

	return Output
end

function Base:Block(Block)
	local Output = ""

	for _, v in ipairs(Block.Statements) do
		Output = Output .. self:Statement(v)
	end

	return Output
end

function Base:UnaryExpression(Expression)
	return self:Token(Expression.Operator) .. self:Expression(Expression.Expression)
end

function Base:ParenExpression(Expression)
	return self:Token(Expression.Parens.Left) .. self:Expression(Expression.Expression) .. self:Token(Expression.Parens.Right)
end

function Base:ValueExpression(Expression)
	return self:Value(Expression.Value)
end

function Base:BinaryExpression(Expression)
	return self:Expression(Expression.Left) .. self:Token(Expression.Operator) .. self:Expression(Expression.Right)
end

function Base:Expression(Expression)
	if Expression == BaseNodes.Expression.Unary then
		return self:UnaryExpression(Expression)
	elseif Expression == BaseNodes.Expression.Paren then
		return self:ParenExpression(Expression)
	elseif Expression == BaseNodes.Expression.Value then
		return self:ValueExpression(Expression)
	elseif Expression == BaseNodes.Expression.Binary then
		return self:BinaryExpression(Expression)
	end

	error("No match")
end

function Base:Field(Field)
	if Field == BaseNodes.Field.Bracket then
		return self:Token(Field.Brackets.Left)
			.. self:Expression(Field.NameExpression)
			.. self:Token(Field.Brackets.Right)
			.. self:Token(Field.Equals)
			.. self:Expression(Field.Expression)
	elseif Field == BaseNodes.Field.Identifier then
		return self:Token(Field.Identifier) .. self:Token(Field.Equals) .. self:Expression(Field.Expression)
	elseif Field == BaseNodes.Field.NoKey then
		return self:Expression(Field.Value)
	end

	error("No match")
end

function Base:Table(Table)
	local Output = self:Token(Table.Braces.Left)

	for _, v in ipairs(Table.Fields.Items) do
		Output = Output .. self:Field(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	return Output .. self:Token(Table.Braces.Right)
end

function Base:Index(Index)
	if Index == BaseNodes.Index.Bracket then
		return self:Token(Index.Brackets.Left)
			.. self:Expression(Index.Expression)
			.. self:Token(Index.Brackets.Right)
	elseif Index == BaseNodes.Index.Dot then
		return self:Token(Index.Dot) .. self:Token(Index.Identifier)
	end

	error("No match")
end

function Base:Value(Value)
	if Value == BaseNodes.Value.Token then
		return self:Token(Value.Value)
	elseif Value == BaseNodes.Value.Function then
		return self:Function(Value.Value)
	elseif Value == BaseNodes.Value.Table then
		return self:Table(Value.Value)
	elseif Value == BaseNodes.Value.FunctionCall then
		return self:FunctionCall(Value.Value)
	elseif Value == BaseNodes.Value.Var then
		return self:Var(Value.Value)
	elseif Value == BaseNodes.Value.ParenExpression then
		return self:ParenExpression(Value.Value)
	end

	error("No match")
end

function Base:NumericFor(For)
	local Output = self:Token(For.For)
		.. self:Token(For.Identifier)
		.. self:Token(For.Equals)
		.. self:Expression(For.StartExpression)
		.. self:Token(For.StartEndComma)
		.. self:Expression(For.EndExpression)
	
	if For.EndStepComma then
		Output = Output .. self:Token(For.EndStepComma) .. self:Expression(For.StepExpression)
	end

	return Output .. self:Token(For.Do) .. self:Block(For.Body) .. self:Token(For.End)
end

function Base:GenericFor(For)
	local Output = self:Token(For.For)

	for _, v in ipairs(For.Identifiers.Items) do
		Output = Output .. self:Token(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	Output = Output .. self:Token(For.In)

	for _, v in ipairs(For.Expressions.Items) do
		Output = Output .. self:Expression(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	return Output .. self:Token(For.Do) .. self:Block(For.Body) .. self:Token(For.End)
end

function Base:If(If)
	local Output = self:Token(If.If)
		.. self:Expression(If.Condition)
		.. self:Token(If.Then)
		.. self:Block(If.Body)
	
	for _, v in ipairs(If.ElseIfs) do
		Output = Output
			.. self:Token(v.ElseIf)
			.. self:Expression(v.Condition)
			.. self:Token(v.Then)
			.. self:Block(v.Body)
	end

	if If.Else then
		Output = Output .. self:Token(If.Else) .. self:Block(If.ElseBody)
	end

	return Output .. self:Token(If.End)
end

function Base:Break(Break)
	return self:Token(Break.Break)
end

function Base:While(While)
	return self:Token(While.While)
		.. self:Expression(While.Condition)
		.. self:Token(While.Do)
		.. self:Block(While.Body)
		.. self:Token(While.End)
end

function Base:Repeat(Repeat)
	return self:Token(Repeat.Repeat)
		.. self:Block(Repeat.Body)
		.. self:Token(Repeat.Until)
		.. self:Expression(Repeat.Condition)
end

function Base:Return(Return)
	local Output = self:Token(Return.Return)
	
	for _, v in ipairs(Return.Expressions.Items) do
		Output = Output .. self:Expression(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	return Output
end

function Base:FunctionArgs(FunctionArgs)
	if FunctionArgs == BaseNodes.FunctionArgs.Paren then
		local Output = self:Token(FunctionArgs.Parens.Left)

		for _, v in ipairs(FunctionArgs.Arguments.Items) do
			Output = Output .. self:Expression(v.Item)

			if v.Separator then
				Output = Output .. self:Token(v.Separator)
			end
		end

		return Output .. self:Token(FunctionArgs.Parens.Right)
	elseif FunctionArgs == BaseNodes.FunctionArgs.String then
		return self:Token(FunctionArgs.Value)
	elseif FunctionArgs == BaseNodes.FunctionArgs.Table then
		return self:Table(FunctionArgs.Value)
	end

	error("No match")
end

function Base:MethodCall(MethodCall)
	return self:Token(MethodCall.Colon)
		.. self:Token(MethodCall.Name)
		.. self:FunctionArgs(MethodCall.Args)
end

function Base:Call(Call)
	if Call == BaseNodes.Call.FunctionArgs then
		return self:FunctionArgs(Call.Value)
	elseif Call == BaseNodes.Call.MethodCall then
		return self:MethodCall(Call.Value)
	end

	error("No match")
end

function Base:Prefix(Prefix)
	if Prefix == BaseNodes.Prefix.ParenExpression then
		return self:ParenExpression(Prefix.Value)
	elseif Prefix == BaseNodes.Prefix.Identifier then
		return self:Token(Prefix.Value)
	end

	error("No match")
end

function Base:Suffix(Suffix)
	if Suffix == BaseNodes.Suffix.Call then
		return self:Call(Suffix.Value)
	elseif Suffix == BaseNodes.Suffix.Index then
		return self:Index(Suffix.Value)
	end

	error("No match")
end

function Base:FunctionBody(FunctionBody)
	local Output = self:Token(FunctionBody.Parens.Left)

	for _, v in ipairs(FunctionBody.Arguments.Items) do
		Output = Output .. self:Token(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	return Output
		.. self:Token(FunctionBody.Parens.Right)
		.. self:Block(FunctionBody.Body)
		.. self:Token(FunctionBody.End)
end

function Base:LocalFunction(LocalFunction)
	return self:Token(LocalFunction.Local)
		.. self:Token(LocalFunction.Function)
		.. self:Token(LocalFunction.Name)
		.. self:FunctionBody(LocalFunction.Body)
end

function Base:FunctionName(FunctionName)
	local Output = ""

	for _, v in ipairs(FunctionName.Names.Items) do
		Output = Output .. self:Token(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	if FunctionName.Colon then
		Output = Output
			.. self:Token(FunctionName.Colon)
			.. self:Token(FunctionName.Method)
	end

	return Output
end

function Base:FunctionDeclaration(FunctionDeclaration)
	return self:Token(FunctionDeclaration.Function)
		.. self:FunctionName(FunctionDeclaration.Name)
		.. self:FunctionBody(FunctionDeclaration.Body)
end

function Base:FunctionCall(FunctionCall)
	local Output = self:Prefix(FunctionCall.Prefix)

	for _, v in ipairs(FunctionCall.Suffixes) do
		Output = Output .. self:Suffix(v)
	end

	return Output
end

function Base:VarExpression(VarExpression)
	return self:FunctionCall(VarExpression)
end

function Base:Var(Var)
	if Var == BaseNodes.Var.VarExpression then
		return self:VarExpression(Var.Value)
	elseif Var == BaseNodes.Var.Identifier then
		return self:Token(Var.Value)
	end

	error("No match")
end

function Base:Assignment(Assignment)
	local Output = ""

	for _, v in ipairs(Assignment.Vars.Items) do
		Output = Output .. self:Var(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	Output = Output .. self:Token(Assignment.Equals)

	for _, v in ipairs(Assignment.Expressions.Items) do
		Output = Output .. self:Expression(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	return Output
end

function Base:LocalAssignment(LocalAssignment)
	local Output = self:Token(LocalAssignment.Local)

	for _, v in ipairs(LocalAssignment.Vars.Items) do
		Output = Output .. self:Var(v.Item)

		if v.Separator then
			Output = Output .. self:Token(v.Separator)
		end
	end

	if LocalAssignment.Equals then
		Output = Output .. self:Token(LocalAssignment.Equals)

		for _, v in ipairs(LocalAssignment.Expressions.Items) do
			Output = Output .. self:Expression(v.Item)

			if v.Separator then
				Output = Output .. self:Token(v.Separator)
			end
		end
	end

	return Output
end

function Base:Do(Do)
	return self:Token(Do.Do) .. self:Block(Do.Body) .. self:Token(Do.End)
end

function Base:Statement(Statement)
	local Output

	if Statement == BaseNodes.Statement.Assignment then
		Output = self:Assignment(Statement.Value)
	elseif Statement == BaseNodes.Statement.Do then
		Output = self:Do(Statement.Value)
	elseif Statement == BaseNodes.Statement.FunctionCall then
		Output = self:FunctionCall(Statement.Value)
	elseif Statement == BaseNodes.Statement.FunctionDeclaration then
		Output = self:FunctionDeclaration(Statement.Value)
	elseif Statement == BaseNodes.Statement.GenericFor then
		Output = self:GenericFor(Statement.Value)
	elseif Statement == BaseNodes.Statement.If then
		Output = self:If(Statement.Value)
	elseif Statement == BaseNodes.Statement.LocalAssignment then
		Output = self:LocalAssignment(Statement.Value)
	elseif Statement == BaseNodes.Statement.LocalFunction then
		Output = self:LocalFunction(Statement.Value)
	elseif Statement == BaseNodes.Statement.NumericFor then
		Output = self:NumericFor(Statement.Value)
	elseif Statement == BaseNodes.Statement.Repeat then
		Output = self:Repeat(Statement.Value)
	elseif Statement == BaseNodes.Statement.While then
		Output = self:While(Statement.Value)
	elseif Statement == BaseNodes.Statement.Return then
		Output = self:Return(Statement.Value)
	elseif Statement == BaseNodes.Statement.Break then
		Output = self:Break(Statement.Value)
	end

	assert(Output, "No match")

	if Statement.Semicolon then
		Output = Output .. self:Token(Statement.Semicolon)
	end

	return Output
end

return Base