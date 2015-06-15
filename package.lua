return {
  name = "gsick/logger",
  version = "0.0.4",
  description = "Logger for Luvit",
  tags = {
    "logger", "log", "logging",
    "file"
  },
  author = {
    name = "Gamaliel Sick"
  },
  homepage = "https://github.com/gsick/lit-logger",
  dependencies = {
    "gsick/clocktime@1.0.0",
  },
  files = {
    "*.lua",
    "libs/*.lua",
    "!tests",
    "!examples"
  }
}
