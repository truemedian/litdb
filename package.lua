return {
	name = "luna-lua/lunar",
	version = "0.1.0",
	description = "A lua parser",
	tags = { "lua", "luna", "parser", "tokenizer", "ast" },
	license = "MIT",
	author = { name = "luna", email = "uncontained0@gmail.com" },
	homepage = "https://github.com/luna-lua/lunar",
	dependencies = {
		"luvit/core",
		"luvit/require",
	},
	files = {
		"**.lua",
		"!test*",
	},
}
