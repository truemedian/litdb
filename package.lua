return {
	name = 'MrEntrasil/Discordis',
	version = '0.0.1',
	homepage = 'https://github.com/MrEntrasil/discordis',
	dependencies = {
		'creationix/coro-http@3.1.0',
		'creationix/coro-websocket@3.1.0',
		'luvit/secure-socket@1.2.2',
        'luvit/require',
        'luvit/pretty-print',
        'luvit/fs',
        'luvit/json',
        'luvit/timer'
	},
	tags = {'discord', 'api', 'wrapper', 'discord wrapper'},
	license = 'MIT',
	author = 'MrEntrasil',
	files = {'**.lua'},
}
