--[[lit-meta
    name = "code-nuage/direct"
    version = "0.0.6"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct.lua"
    dependencies = {
        "code-nuage/direct-server",
        "code-nuage/direct-router",
        "code-nuage/direct-reasons",
        "code-nuage/direct-mime",
        "code-nuage/direct-colors",
        "code-nuage/direct-verbosity",
        "code-nuage/direct-publicize",
        "code-nuage/direct-logs"
    }
    description = "direct web microframework."
    tags = { "direct" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+                     +--
--  direct-framework     --
--  @code-nuage          --
--+                     +--

return {
    -- Tools
    server = require("direct-server"),
    router = require("direct-router"),

    -- Utils
    reasons = require("direct-reasons"),
    mime = require("direct-mime"),
    colors = require("direct-colors"),

    -- Router's plugins
    verbosity = require("direct-verbosity"),
    publicize = require("direct-publicize"),
    logs = require("direct-logs"),
}
