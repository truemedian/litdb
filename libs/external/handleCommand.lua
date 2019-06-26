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
		
			if data.commands[parsedCommand[1]].whitelist then
			
				if not data.commands[parsedCommand[1]].whitelist[message.author.id] then
					message.channel:send(":x: You are not allowed to use this command.")
					return true
				end
			end
			
			-- Check if user inputed correct number of arguments.
			if (#parsedCommand - 1) == data.commands[parsedCommand[1]].numberOfArguments then
				local messageobj = data.commands[parsedCommand[1]].handler(message)
				
			else
				message.channel:sendf(":x: You did not specify the correct number of arguments. Usage: %s%s", data.meta.prefix, data.commands[parsedCommand[1]].usage)
			end
			
		else
			message.channel:send(":x: The command you entered is unknown.")
		end
		
	else
		return false
	end
	
end