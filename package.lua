return {
  name = "gsick/sqlite3",
  version = "0.1.0",
  description = "SQLite3 ffi wrapper for Luvit",
  tags = {
    "db", "database", "sqlite", "sqlite3"
  },
  author = {
    name = "Gamaliel Sick"
  },
  homepage = "https://github.com/gsick/lit-sqlite3",
  dependencies = {
    "luvit/require@1.2.0",
    "luvit/path@1.0.0",
    "luvit/fs@1.2.0"
  },
  files = {
    "*.lua",
    "libs/$OS-$ARCH/*",
    "libs/*.h",
    "!tests",
    "!examples"
  }
}
