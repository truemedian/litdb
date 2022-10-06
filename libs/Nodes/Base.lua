local Node = require("Nodes/Node")

local Block = Node.Node:extend()

function Block:initialize(Options)
	self.Statements = Options.Statements
end

local Expression = Node.Enum:new({
	"Unary",
	"Paren",
	"Value",
	"Binary",
})

local Value = Node.Enum:new({
	"Token",
	"Function",
	"Table",
	"FunctionCall",
	"Var",
	"Paren",
})

local Field = Node.Enum:new({
	"Bracket",
	"Identifier",
	"NoKey",
})

local Table = Node.Node:extend()

function Table:initialize(Options)
	self.Braces = Options.Braces
	self.Fields = Options.Fields
end

local Index = Node.Enum:new({
	"Bracket",
	"Dot",
})

local For = Node.Enum:new({
	"Numeric",
	"Generic",
})

local ElseIf = Node.Node:extend()

function ElseIf:initialize(Options)
	self.ElseIf = Options.ElseIf
	self.Condition = Options.Condition
	self.Then = Options.Then
	self.Body = Options.Body
end

local If = Node.Node:extend()

function If:initialize(Options)
	self.If = Options.If
	self.Condition = Options.Condition
	self.Then = Options.Then
	self.Body = Options.Body
	self.ElseIfs = Options.ElseIfs
	self.Else = Options.Else
	self.ElseBody = Options.ElseBody
	self.End = Options.End
end

local Break = Node.Node:extend()

function Break:initialize(Options)
	self.Break = Options.Break
end

local While = Node.Node:extend()

function While:initialize(Options)
	self.While = Options.While
	self.Condition = Options.Condition
	self.Do = Options.Do
	self.Body = Options.Body
	self.Breaks = Options.Breaks
	self.End = Options.End
end

local Repeat = Node.Node:extend()

function Repeat:initialize(Options)
	self.Repeat = Options.Repeat
	self.Body = Options.Body
	self.Breaks = Options.Breaks
	self.Until = Options.Until
	self.Condition = Options.Condition
end

local Return = Node.Node:extend()

function Return:initialize(Options)
	self.Return = Options.Return
	self.Expressions = Options.Expressions
end

local FunctionArgs = Node.Enum:new({
	"Paren",
	"String",
	"Table",
})

local MethodCall = Node.Node:extend()

function MethodCall:initialize(Options)
	self.Colon = Options.Colon
	self.Name = Options.Name
	self.Args = Options.Args
end

local Call = Node.Enum:new({
	"FunctionArgs",
	"MethodCall",
})

local Prefix = Node.Enum:new({
	"ParenExpression",
	"Identifier",
})

local Suffix = Node.Enum:new({
	"Call",
	"Index",
})

local FunctionBody = Node.Node:extend()

function FunctionBody:initialize(Options)
	self.Arguments = Options.Arguments
	self.Body = Options.Body
	self.Returns = Options.Returns
	self.End = Options.End
	self.Parens = Options.Parens
end

local LocalFunction = Node.Node:extend()

function LocalFunction:initialize(Options)
	self.Local = Options.Local
	self.Function = Options.Function
	self.Name = Options.Name
	self.Body = Options.Body
end

local FunctionName = Node.Node:extend()

function FunctionName:initialize(Options)
	self.Names = Options.Names
	self.Colon = Options.Colon
	self.Method = Options.Method
end

local FunctionDeclaration = Node.Node:extend()

function FunctionDeclaration:initialize(Options)
	self.Function = Options.Function
	self.Name = Options.Name
	self.Body = Options.Body
end

local FunctionCall = Node.Node:extend()

function FunctionCall:initialize(Options)
	self.Prefix = Options.Prefix
	self.Suffixes = Options.Suffixes
end

local VarExpression = Node.Node:extend()

function VarExpression:initialize(Options)
	self.Prefix = Options.Prefix
	self.Suffixes = Options.Suffixes
end

local Var = Node.Enum:new({
	"VarExpression",
	"Identifier",
})

local Assignment = Node.Node:extend()

function Assignment:initialize(Options)
	self.Vars = Options.Vars
	self.Equals = Options.Equals
	self.Expressions = Options.Expressions
end

local LocalAssignment = Node.Node:extend()

function LocalAssignment:initialize(Options)
	self.Local = Options.Local
	self.Vars = Options.Vars
	self.Equals = Options.Equals
	self.Expressions = Options.Expressions
end

local Do = Node.Node:extend()

function Do:initialize(Options)
	self.Do = Options.Do
	self.Body = Options.Body
	self.End = Options.End
end

local Statement = Node.Enum:new({
	"Assignment",
	"Do",
	"FunctionCall",
	"FunctionDeclaration",
	"GenericFor",
	"If",
	"LocalAssignment",
	"LocalFunction",
	"NumericFor",
	"Repeat",
	"While",
	"Return",
	"Break",
})

return {
	Block = Block,
	Expression = Expression,
	Value = Value,
	Field = Field,
	Table = Table,
	Index = Index,
	For = For,
	ElseIf = ElseIf,
	If = If,
	Break = Break,
	While = While,
	Repeat = Repeat,
	Return = Return,
	FunctionArgs = FunctionArgs,
	MethodCall = MethodCall,
	Call = Call,
	Prefix = Prefix,
	Suffix = Suffix,
	FunctionBody = FunctionBody,
	LocalFunction = LocalFunction,
	FunctionName = FunctionName,
	FunctionDeclaration = FunctionDeclaration,
	FunctionCall = FunctionCall,
	VarExpression = VarExpression,
	Var = Var,
	Assignment = Assignment,
	LocalAssignment = LocalAssignment,
	Do = Do,
	Statement = Statement,
}