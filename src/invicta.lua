local commandHandler = require './commandHandler'
local loader = require './loader'
local config = require './config'
local toast = require 'toast'
local util = require './util'
local sql = require 'sqlite3'

local conn = sql.open 'invicta.db'
local client = toast.Client {
	prefix = config.prefix,
	commandHandler = function(msg)
		return commandHandler(msg, conn)
	end,
	defaultHelp = true
}

local function setupGuild(id)
	conn:exec('INSERT INTO guild_settings (guild_id) VALUES (\''..id..'\')')
end

-- Events

client:on('ready', function()
	for guild in client.guilds:iter() do
		if not util.getGuildSettings(guild.id, conn) then
			setupGuild(guild.id)
		end
	end
end)

client:on('guildCreate', function(guild)
	if not util.getGuildSettings(guild.id, conn) then
		setupGuild(guild.id)
	end
end)
-- Commands

for _, command in pairs(loader.loadCommands('commands')) do
	client:addCommand(command)
end

client:login(config.token)