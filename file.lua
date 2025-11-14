--[[lit-meta
    name = "code-nuage/direct"
    version = "0.0.5"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct.lua"
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

    -- Router's plugins
    verbosity = require("direct-verbosity"),
    publicize = require("direct-publicize"),
    logs = require("direct-logs"),
}