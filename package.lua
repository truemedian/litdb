  return {
    name = "qwreey/@qwreey",
    version = "0.0.1",
    description = "Package holder",
    tags = { "lua", "lit", "luvit" },
    license = "MIT",
    author = { name = "qwreey", email = "me@qwreey.moe" },
    dependencies = {
      "luvit/luvit",
      "creationix/coro-channel",
      "creationix/coro-http",
      "creationix/coro-net",
      "creationix/nibs",
      "creationix/coro-fs",
      "creationix/sha1",
      "qwreey/mutex",
      "qwreey/promise",
      "qwreey/random",
      "qwreey/parser",
      "qwreey/profiler",
    },
    files = {
      "**.lua",
      "!test*"
    }
  }
  
