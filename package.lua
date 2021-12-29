return {
    name = "Uncontained0/Lublox",
    version = "0.0.15",
    description = "A roblox webapi wrapper for luvit.",
    tags = { "roblox", "webapi", "web", "api", "rblx" },
    license = "MIT",
    author = { name = "Uncontained0", email = "uncontained0@gmail.com" },
    homepage = "https://github.com/Uncontained0/Lublox",
    dependencies = {
        "creationix/coro-http@3.1.0",
		"creationix/coro-websocket@3.1.0",
		"luvit/secure-socket@1.2.2",
    },
    files = {
        "**.lua",
        "!test",
    }
}
  