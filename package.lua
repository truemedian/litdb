return {
    name = "code-nuage/direct",
    version = "0.0.2",
    description = "A fullstack framework",
    tags = { "lua", "lit", "luvit" },
    license = "MIT",
    author = { name = "code-nuage", email = "eloi.hariot@protonmail.com" },
    homepage = "https://github.com/code-nuage/direct",
    dependencies = {
        "luvit/coro-http",
        "luvit/coro-fs"
    },
    files = {
        "**.lua",
        "!test*"
    }
}
