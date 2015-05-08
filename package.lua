return {
  name = "creationix/termbox",
  version = "1.1.0",
  homepage = "https://github.com/creationix/lit-termbox",
  description = "FFI bindings to the termbox tty library",
  tags = {"ffi", "tty"},
  author = { name = "Tim Caswell" },
  license = "MIT",
  files = {
    "*.lua",
    "*.h",
    "!termbox",
    "!termbox-sample",
    "$OS-$ARCH/*",
  }
}
