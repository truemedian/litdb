return {
  name = "creationix/hoedown",
  version = "1.0.6",
  homepage = "https://github.com/creationix/lit-hoedown",
  dependencies = {
    "creationix/ffi-loader@1.0.0"
  },
  files = {
    "*.lua",
    "*.h",
    "!hoedown",
    "!hoedown-sample",
    "$OS-$ARCH/*",
  }
}
