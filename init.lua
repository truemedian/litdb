local main = require 'lua-extentions'()
local client = require 'discordia'.Client()

local cache = {
	_core = { },
	_master = require 'commands',
	_prefix = '!' -- default prefix
}

for name, fn in pairs(require 'core' ) do
	cache._core[name] = fn
end

cache._master._parent = function()
	return cache
end

_G.bot = {
	connections = { }
}

client:on('voiceDisconnect', function(member)
	if member.user.id ~= client.user.id then return end

	bot.connections[member.guild.id] = nil
end)

local function compress(message)
	local author = message.author
	if client.user.id == author.id or author.bot then
		return nil
	end

	local content = message.content

	local prefix = content:sub(1, #cache._prefix)
	if cache._prefix ~= prefix:lower() then
		return nil
	end

	local split = content:sub(#prefix + 1):split(' ')
	if #split == 0 then return nil end

	local command = split[1]
	table.remove(split, 1)

	local _, n = table.find(cache._master, command and command:lower() or '', true)

	if not n then return nil end
	local fnc = cache._master[n]

	if type(fnc) == 'table' and getmetatable(fnc) then
		fnc( { message = message, split = split, command = command } )
	end
end

client:on('messageCreate', compress); client:on('messageUpdate', compress)

client:run(	string.format('Bot %s', args[2]) )