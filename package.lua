return {
  name = "mrtnpwn/plug",
  version = "1.1.0",
  description = "The *awesome* Mini World: Block Art Plugin Framework.",
  tags = { "lua", "luvit", "mwba", "plugin", "framework" },
  license = "MIT",
  author = { name = "Martin Aguilar" },
  homepage = "https://github.com/mrtnpwn/plug",
  dependencies = {
    -- JSON encoding/decoding
    'luvit/json'
  },
  files = {
    "**.lua",
    "!test*"
  }
}
