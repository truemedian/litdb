return {
  name = "rphillips/nntp",
  version = "0.0.3",
  dependencies = {
    "creationix/require@1.0.2",
    "creationix/coro-fs@1.2.3",
    "creationix/coro-tcp@1.0.2",
    "creationix/coro-tls@1.1.0",
    "creationix/coro-wrapper@0.1.0",
    "creationix/pretty-print@0.1.0",
  },
  files = {
    "**.lua",
    "!nntp",
    "!lit*",
    "!main.lua",
  }
}
