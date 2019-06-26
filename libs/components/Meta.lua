local data = require('internal/data')

return function(name)

	return function (description)
		data.meta = {
			name = name,
			description = description.description,
			prefix = description.prefix
		}
	end
end