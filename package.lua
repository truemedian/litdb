return {
  name = "voronianski/cookie",
  version = "1.0.1",
  description = "Basic HTTP cookie parser and serializer for HTTP servers",
  tags = { "lua", "lit", "luvit", "cookies", "parser", "http", "server", "serialize" },
  license = "MIT",
  author = { name = "Dmitri Voronianski", email = "dmitri.voronianski@gmail.com" },
  homepage = "https://github.com/luvitrocks/cookie",
  dependencies = {
    'filwisher/lua-tape'
  },
  files = {
    "**.lua",
    "!test*"
  }
}
