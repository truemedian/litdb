local library = {
	math = require './libs/math',
	table = require './libs/table',
	string = require './libs/string',
	package = require './package'
}

local utils = require 'utils'
for name, fn in pairs(utils) do
	library[name] = fn
end

--- Serealizes the Lua extensions in a compact mode.
library = setmetatable(library, {
	--- Initializes the module and adds the functions to the global environment.
	---@param self {}
	---@param notGlobal any
	---@return table library
	__call = function(self, notGlobal)
		for key, tab in pairs(self) do
			if key ~= 'package' then
				if not _G[key] and not notGlobal then
					_G[key] = tab
				elseif type(tab) == 'table' then
					if _G[key] and not notGlobal then
						for name, fn in pairs(tab) do
							_G[key][name] = fn
						end
					else
						local lib = _G[key] or { }
						for k, v in pairs(lib) do
							tab[k] = v
						end
					end
				end
			end
		end

		return self
	end
})

return library