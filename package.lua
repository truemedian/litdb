return {
  name = "creationix/termbox",
  version = "1.0.6",
  homepage = "https://github.com/creationix/lit-termbox",
  dependencies = {
    "creationix/ffi-loader@1.0.0",
  },
  files = {
    "*.lua",
    "*.h",
    "!termbox",
    "!termbox-sample",
    "$OS-$ARCH/*",
  }
}
