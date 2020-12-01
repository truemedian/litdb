local discordia = require 'discordia'
local toast = require 'toast'
local util = require './util'

local class, enums = discordia.class, discordia.enums

local function search(tbl, q)
	for i, k in pairs(tbl) do
		if q == k then
		   return i
		end
	 end
end

return function(msg, conn)

	if msg.author.bot then return end

	if msg.guild and not msg.guild:getMember(msg.client.user.id):hasPermission(enums.permission.sendMessages) then
	   return
	end


	local self = msg.client
	local settings = util.getGuildSettings(msg.guild and msg.guild.id, conn)

	if msg.content == '<@!' .. msg.client.user.id .. '>' then
		return msg:reply(string.format('My prefix is `%s`%s',
			self._prefix[1],
			settings.prefix and settings.prefix ~= self._prefix[1] and ', but on this server it\'s `' .. settings.prefix .. '`' or '')
		)
	end

	local toMatch = settings.prefix or self._prefix[1]
	local prefix = msg.content:find(toMatch, 1, true) == 1 and toMatch

	if not prefix then return end

	local cmd, msgArg = string.match(msg.cleanContent:sub(#toMatch + 1), '^(%S+)%s*(.*)')

	if not cmd then return end

	cmd = cmd:lower()

	local args = {}
	for arg in string.gmatch(msgArg, '%S+') do
	   table.insert(args, arg)
	end

	local command

	for _, v in pairs(self._commands) do
		if v.name == cmd or search(v.aliases, cmd) then
		   command = v
		   break
		end
	 end

	if not command then return end

	for _, v in pairs(command.subCommands) do
		if v.name == args[1] then
		   table.remove(args, 1)
		   command = v
		   break
		end
	 end

	local check, content = command:check(msg)
	if not check then return msg:reply(toast.util.errorEmbed(nil, content)) end

	if command:onCooldown(msg.author.id) then
	   local _, time = command:onCooldown(msg.author.id)
	   return msg:reply(toast.util.errorEmbed('Slow down, you\'re on cooldown', 'Please wait ' .. toast.util.formatLongfunction(time)))
	end

	command.hooks.preCommand(msg)

	local success, err = pcall(command.execute, msg, args, conn, command)

	command.hooks.postCommand(msg, class.type(err) == 'Message' and err or nil)

	if not success then
	   self:error('ERROR WITH ' .. command.name .. ': ' .. err)
	   msg:reply(toast.util.errorEmbed(nil, 'Please try this command later'))
	else
	   command:startCooldown(msg.author.id)
	end
end