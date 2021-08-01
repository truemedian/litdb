return {
    name = 'lettuce-magician/DuaHook',
	version = '0.0.1',
	dependencies = {
		'creationix/coro-http',
		'luvit/secure-socket',
	},
	tags = {'discord', 'webhook', 'api'},
	license = 'MIT',
	author = 'Lettuce',
	files = {
        '**.lua',
        '!.gitignore',
        '!deps'
    },
}