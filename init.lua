
-- direct
-- A Lua web microframework
-- @code-nuage

local html = require("./html.lua")
local loader = require("./loader.lua")
local mime = require("./mime.lua")
local reasons = require("./reasons.lua")
local router = require("./router.lua")
local xml = require("./xml.lua")

local direct = {
    ["html"] = html,
    ["mime"] = mime,
    ["loader"] = loader,
    ["reasons"] = reasons,
    ["router"] = router,
    ["xml"] = xml
}

return direct
