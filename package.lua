  return {
  name = "4keef/pastor",
  version = "0.1.0",
  description = "Fetch bible verses from api",
  tags = { "lua", "lit", "luvit", "bible", "api", "http" },
  license = "MIT",
  author = { name = "4keef", email = "keef.devv@gmail.com" },
  homepage = "https://github.com/4keef/pastor",
  dependencies = {
    "creationix/coro-http",
    "luvit/secure-socket@"
  },
  files = {
    "**.lua",
    "!test*"
  }
}

