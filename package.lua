return
{
	license = 'MIT',
	version = '0.0.1a',
	name = 'satom99/litcord',
	description = "Yet another unofficial Lua client API for Discord.",
	author = "Santi 'AdamJames' T. <satom99@github>",
	homepage = 'https://github.com/satom99/litcord',
	tags =
	{
		'lua',
		'luvit',
		'discord',
		'api',
	},
	files = {
		'*.lua',
		'client/*.lua',
		'classes/*.lua',
		'constants/*.lua',
		'structures/*.lua',
	},
	dependencies = {
		'creationix/coro-http@2.1.1',
		'creationix/coro-websocket@1.0.0-1',
	},
}