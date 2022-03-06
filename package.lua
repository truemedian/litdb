return {
    name = "Uncontained0/Lublox",
    version = "0.1.2",
    description = "An object-oriented lua wrapper for the Roblox web API.",
    tags = { "roblox", "webapi", "web", "api", "rblx"},
    license = "MIT",
    author = { name = "Uncontained0", email = "uncontained0@gmail.com" },
    homepage = "https://github.com/Uncontained0/Lublox",
    dependencies = {
        "creationix/coro-http",
		"creationix/coro-websocket",
		"luvit/secure-socket",
    },
    files = {
        "**.lua",
        "!test",
        "!docs",
    }
}
  