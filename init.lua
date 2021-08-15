
--[[   
    LuauProgrammer
    init.lua
    Requires & Returns all files within the containers directory
]]

return {
    users = require("./containers/users"),
    groups = require("./containers/groups"),
    authentication = require("./containers/authentication"),
    games = require("./containers/games"),
}