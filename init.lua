--[[lit-meta
	name = "MrEntrasil/Discordis"
	version = "0.0.1"
	homepage = "https://github.com/MrEntrasil/discordis"
	description = "A simple discord wrapper written in lua"
	license = "MIT"
]]

return {
    Client = require("./client/core"),
    enum = require("./utils/enum"),
    functions = require("./utils/functions"),
    db = require("./utils/db"),
}
