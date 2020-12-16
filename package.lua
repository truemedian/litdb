return {
  name = "SovietKitsune/slashCommands",
  version = "1.0.0",
  description = "Add slash commands to discordia 2.x",
  tags = { "discordia", "lua" },
  license = "MIT",
  author = { name = "Soviet Kitsune", email = "sovietkitsune@soviet.solutions" },
  homepage = "https://github.com/SovietKitsune/slashCommands",
  dependencies = {
    "SinisterRectus/discordia@2.8.4"
  },
  files = {
    "**.lua",
    "!test*",
    "!private",
    "!main.lua"
  }
}