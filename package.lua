return {
	name = "truemedian/lfs",
	version = "0.1.1",
	description = "A libuv equivalent for the popular lfs library",
	tags = { "lua", "lfs", "filesystem" },
	license = "MIT",
	author = { name = "Nameless", email = "truemedian@gmail.com" },
	homepage = "https://keplerproject.github.io/luafilesystem",
	dependencies = { },
	files = {
		"**.lua",
		"!deps",
		"!test*"
	}
}
