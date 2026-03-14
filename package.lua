return {
  name = "Bilal2453/luasql-odbc",
  version = "2.8.0-4",
  description = "LuaSQL is a simple interface from Lua to a DBMS. This build includes ODBC driver only.",
  tags = {},
  license = "MIT",
  author = { name = "Bilal2453", email = "lit@bilal0.dev" },
  homepage = "https://github.com/my-luvit/lit-luasql/blob/lit-luasql-odbc/",
  dependencies = {},
  files = {
    -- the reason we have x64/x86_64 duplicated is a regression in lit 2.15.0
    -- which accidentally changed the format
    "$OS-$ARCH/*",
    "$OS-$ARCH_64/*",
    "**.lua",
  }
}
