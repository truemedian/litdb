return {
  name = "creationix/tweetnacl",
  version = "0.0.2",
  homepage = "https://github.com/creationix/littweetnacl",
  description = "luatweetnacl bindings packaged for lit applications.",
  tags = {"nacl","crypto"},
  author = { name = "Tim Caswell" },
  license = "MIT",
  main = "$OS-$ARCH/luatweetnacl.so",
  files = {
    "init.lua",
    "package.lua",
    "$OS-$ARCH/*"
  }
}
