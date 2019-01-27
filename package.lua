return {
  name = "mrtnpwn/plug",
  version = "0.0.1",
  description = "The *awesome* Mini World: Block Art Plugin Framework.",
  tags = { "lua", "luvit", "mwba", "plugin", "framework" },
  license = "MIT",
  author = { name = "Martin Aguilar" },
  homepage = "https://github.com/mrtnpwn/plug",
  dependencies = {
    -- UUID v4 Generation
    'mrtnpwn/luv4',
    -- JSON encoding/decoding
    'luvit/json'
  },
  files = {
    "**.lua",
    "!test*"
  }
}
