return {
  name = "virgo-agent-toolkit/split-stream",
  version = "0.6.3",
  description = "a Transform stream that (re-)splits upstream string into chunks based on provided separator",
  contributors = {
    {
      name = "Robert Chiniquy",
      email = "robert.chiniquy@rackspace.com",
      url = "https://robert-chiniquy.github.io/",
    },
    {
      name = "Ryan Phillips",
      email = "ryan.phillips@rackspace.com",
      url = "http://trolocsis.com/",
    },
    {
      name = "Rob Emanuele",
      email = "rje@ieee.org",
      url = "http://rob.emanuele.us/",
    },
  },
  licenses = {"Apache-2.0"},
  dependencies = {
    "luvit/luvit@2"
  },
  files = {
    "**.lua",
    "!tests"
  }
}
