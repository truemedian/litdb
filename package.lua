return {
	name = 'RainyXeon/lunalink',
	version = '0.0.3',
	description = 'A simple description of my little package.',
	tags = { 'lua', 'lit', 'luvit' },
	license = 'MIT',
	author = {
		name = 'RainyXeon',
		email = 'xeondev@xeondex.onmicrosoft.com',
	},
	homepage = 'https://github.com/LunaticSea/lunalink',
	dependencies = {
		'luvit/coro-http@3.2.4',
		'luvit/coro-websocket@3.1.1',
		'luvit/secure-socket@1.2.4',
	},
	files = {
		'**.lua',
		'!test*',
		'!bot.lua',
	},
}
