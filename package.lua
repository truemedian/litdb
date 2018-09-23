return {
	name = "truemedian/luvit-reql",
	version = "1.0.5",
	description = "A rethinkdb driver for Luvit, please send me a message if you need any assistance or extra features not currently present. --- forked from DannehSC/luvit-reql",
	tags = { "luvit", "rethinkdb", "database", "driver" },
	license = "MIT",
	author = "DannehSC",
	homepage = "https://github.com/truemedian/luvit-reql",
	dependencies = {
		'creationix/coro-net'
	},
	files = {
		"**.lua",
		"!test*"
	}
}