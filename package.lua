return {
  name = "virgo-agent-toolkit/virgo",
  version = "0.11.2",
  dependencies = {
    "luvit/luvit@2.0.1",
    "rphillips/async@0.0.2",
    "rphillips/hsm@0.0.2",
    "rphillips/line-emitter@0.3.3",
    "rphillips/logging@0.1.3",
    "rphillips/split-stream@0.4.0",
    "virgo-agent-toolkit/request@0.2.2",
  },
  files = {
    "**.lua",
    "!lit*",
    "!test*"
  }
}
