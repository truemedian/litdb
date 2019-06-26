local data = require('internal/data')
local utility = require('internal/utility')

return function(name)
	return function(description)
		data.commands[name] = {
			description = description.description,
			usage = description.usage,
			whitelist = utility.protectedReverse(description.whitelist),
			numberOfArguments = description.args,
			response = description.response,
			confirmation = description.confirmation
		}
	end
end