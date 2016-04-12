return {
	name = "LennyPenny/simplerpc",
	version = "1.0.3",
	description = "Simple JSON-RPC 2.0 server",
	tags = { "lua", "lit", "luvit" },
	license = "MIT",
	author = { name = "Lennart Bernhardt", email = "l.bernhardt@live.de" },
	homepage = "http://github.com/LennyPenny/simplerpc-luvit",
	dependencies = {
		"creationix/weblit@2.1.1",
		"luvit/json@2.5.2"
	},
	files = {
	  "simplerpc.lua",
	  "package.lua",
	}
}
