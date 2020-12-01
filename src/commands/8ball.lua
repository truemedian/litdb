local responses = {
	'It is certain', 'Without a doubt', 'You may rely on it', 'Yes definitely', 'It is decidedly so',
	'As I see it, yes', 'Most likely', 'Yes', 'Outlook good', 'Signs point to yes', -- Positive

	'Don\'t count on it', 'Outlook not so good', 'My sources say no', 'Very doubtful',
	'My reply is no', -- Negative

	'Reply hazy try again', 'Better not tell you now', 'Ask again later', 'Cannot predict now',
	'Concentrate and ask again' -- Neutral
}

return {
	name = '8ball',
	description = 'Ask the 8ball anything!',
	example = '8ball <question>',
	execute = function(msg, args)
		if #args <= 0 then return msg:reply('You didn\'t ask anything') end
		msg:reply(responses[math.random(#responses)])
	end
}