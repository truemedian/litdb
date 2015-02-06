return {
  name = "rphillips/split-stream",
  version = "0.4.0",
  description = "a Transform stream that (re-)splits upstream string into chunks based on provided separator",
  repository = {
    url = "https://github.com/virgo-agent-toolkit/luvit-split-stream.git",
  },
  author = {
    name = "Song Gao",
    email = "song@gao.io",
    url = "https://song.gao.io",
  },
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
  dependencies = { },
  devDependencies = {
    ["tape"] = "https://github.com/virgo-agent-toolkit/luvit-tape",
  },
  main = 'init.lua',
}
