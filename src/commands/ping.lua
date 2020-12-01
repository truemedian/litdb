return {
	name = 'ping',
	description = 'Use this to check if the bot is offline.',
	execute = function(msg)
		return msg:reply('Pong!')
	end
}