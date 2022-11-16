return {
	name = "alphafantomu/luv-lz4",
	version = "0.0.1",
	description = "C bindings for lz4 in LuaJIT",
	tags = { "luvit", "luv", "compression", "c", "bindings" },
	license = "MIT",
	author = { name = "Ari Kumikaeru"},
	homepage = "https://github.com/alphafantomu/luv-lz4",
	dependencies = {},
	files = {
	 	"**.lua",
		"libs/$OS-$ARCH/*",
		"!tests*"
	}
}