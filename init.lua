
-- direct
-- A Lua web microframework
-- @code-nuage

local html = require("./libs/html.lua")
local loader = require("./libs/loader.lua")
local mime = require("./libs/mime.lua")
local reasons = require("./libs/reasons.lua")
local router = require("./libs/router.lua")
local xml = require("./libs/xml.lua")

local direct = {
    ["html"] = html,
    ["mime"] = mime,
    ["loader"] = loader,
    ["reasons"] = reasons,
    ["router"] = router,
    ["xml"] = xml
}

return direct
