return {
  name = 'kaustavha/luvit-walk',
  version = "1.0.2",
  license = "Apache 2",
  homepage = "https://github.com/kaustavha/luvit-read-directory-recursive",
  description = "Recursively dives through directories and read the contents of all the children directories.",
  tags = {"luvit", "fs", "readdirrecursive" },
  dependencies = { "luvit/luvit@2" },
  author = { name = 'Kaustav Haldar'},
  main = { 'init.lua' },
  files = {
    '**.lua',
    '!tests',
  }
}
