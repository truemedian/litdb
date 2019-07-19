local data = require('internal/data')

return function(name)
	return function(description)
		data.commands[name] = {
			description = description.description,
			usage = description.usage,
			minimumArguments = description.minimumArguments,
			maximumArguments = description.maximumArguments,
			numberOfArguments = description.args,
			response = description.response
		}
	end
end
