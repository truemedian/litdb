local Node = require("Nodes/Node")

local Pair = Node.Node:extend()

function Pair:initialize(Left, Right)
	self.Left = Left
	self.Right = Right
end

local Punctuated = Node.Node:extend()

function Punctuated:initialize()
	self.Items = {}
	self.Active = true
end

function Punctuated:Push(Item, Separator)
	assert(self.Active, "Cannot push to an ended Punctuated")
	table.insert(self.Items, { Item = Item, Separator = Separator })
end

function Punctuated:End(Item)
	table.insert(self.Items, { Item = Item, Separator = nil })
	self.Active = false
end

return {
	Pair = Pair,
	Punctuated = Punctuated,
}