-- Probably the messiest file in this project.
-- TODO: Refactor

local data = require('internal/data')
local utility = require('internal/utility')
local generateHelp = require('internal/generateHelp')

return function(message)
	-- Get prefix, and message without the prefix.
	local prefix = string.sub(message.content, 0, #data.meta.prefix)
	local withoutPrefix = string.sub(message.content, #data.meta.prefix + 1)

	if prefix == data.meta.prefix then
		local parsedCommand = utility.split(withoutPrefix)

		if parsedCommand[1] == "help" then
			generateHelp(message)

		elseif data.commands[parsedCommand[1]] then -- Check if command is valid.

			local command = data.commands[parsedCommand[1]]

			if command.whitelist then

				if not command.whitelist[message.author.id] then
					message.channel:send(":x: You are not allowed to use this command.")
					return true
				end
			end

			-- Check if user inputed correct number of arguments.
			if (#parsedCommand - 1) == command.numberOfArguments then

				if type(command.response) == "function" then
					command.response(message)
				elseif type(command.response) == "string" or type(command.response) == "table" then

					local sentMessage = message.channel:send(command.response)

					if command.confirmation then
						data.confirmation[sentMessage.id] = {original = message, response = sentMessage, handler = command.confirmation}

						sentMessage:addReaction("✅")
						sentMessage:addReaction("❌")
					end
				end

			else
				message.channel:sendf(":x: You did not use the correct number of arguments. Usage: %s%s", data.meta.prefix, command.usage)
			end

		else
			message.channel:send(":x: The command you entered is unknown.")
		end

	else
		return false
	end
	
end