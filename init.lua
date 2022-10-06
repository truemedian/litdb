return {
	Nodes = {
		Base = require("Nodes/Base"),
		Util = require("Nodes/Util"),
		Node = require("Nodes/Node"),
	},

	Parsers = {
		Base = require("Parsers/Base"),
		Parser = require("Parsers/Parser"),
	},

	Lexers = {
		Base = require("Lexers/Base"),
		Lexer = require("Lexers/Lexer"),
	},

	Generators = {
		Base = require("Generators/Base"),
		Generator = require("Generators/Generator"),
	},

	TokenList = require("TokenList"),
}