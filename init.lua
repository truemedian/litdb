
-- direct
-- A Lua web microframework
-- @code-nuage

local html = require("./libs/html.lua")
local mime = require("./libs/mime.lua")
local reasons = require("./libs/reasons.lua")
local router = require("./libs/router.lua")
local xml = require("./libs/xml.lua")

local direct = {
    ["html"] = html,
    ["mime"] = mime,
    ["reasons"] = reasons,
    ["router"] = router,
    ["xml"] = xml
}

return direct
