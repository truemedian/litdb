--[[lit-meta
    name = "code-nuage/evasive"
    version = "0.0.1"
    homepage = "https://github.com/code-nuage/evasive/blob/main/evasive.lua"
    dependencies = {
        "code-nuage/evasive-page"
    }
    description = "evasive framework, running on top of direct."
    tags = { "evasive" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+                   +--
--  evasive-component  --
--  @code-nuage        --
--+                   +--
return {
    page = require("evasive-page")
}