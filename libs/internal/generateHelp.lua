local data = require('internal/data')

return function(message)
	local help = {}

	for c, v in pairs(data.commands) do
		table.insert(help, {
			name = data.meta.prefix .. c,
			value = string.format("%s\nUsage: %s%s", v.description, data.meta.prefix, v.usage),
			inline = true
		})
	end

	message.channel:send {
		embed = {
			title = data.meta.name .. " - Help",
			description = data.meta.description,
			fields = help
		}
	}
end
