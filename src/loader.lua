local fs = require 'fs'
local pathjoin = require 'pathjoin'

local pathJoin = pathjoin.pathJoin
local handler = {}

function handler.loadCommands(dir)
	local commands = {}
	for name, type in fs.scandirSync(dir) do
		if type == 'directory' then
			local path = pathJoin(dir, name)
			local buf = handler.loadCommands(path)
			for _, command in ipairs(buf) do
				table.insert(commands, command)
			end
		elseif type == 'file' and name:match('%.lua$') then
			table.insert(commands, require('./' .. pathJoin(dir, name)))
		end
	end
	return commands
end

return handler