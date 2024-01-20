  return {
    name = "Richy-Z/lua-edulink",
    version = "0.0.1",
    description = "EduLink One API integration for Luvit",
    tags = { "edulink", "api", "luvit", "http", "school", "education", "coro-http", "json", "UK", "england", "scotland", "wales", "ireland" },
    license = "MIT",
    author = { name = "Richy Z.", email = "64844585+Richy-Z@users.noreply.github.com" },
    homepage = "https://github.com/Richy-Z/lua-edulink",
    dependencies = {
      "luvit/require",
      "luvit/secure-socket",
      
      "luvit/json",
      "creationix/coro-http",
    },
    files = {
      "**.lua",
      "!test*"
    }
  }
  