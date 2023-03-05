local content = require 'content'

local function getn(table)
	local n = 0
	for _ in pairs(table) do
		n = n + 1
	end
	return n
end

local function save(self)
	local handle = self:getHandle()
	if not handle then return nil end

	local value = self:getPathNames()


	return handle:apply {
		key = 'props',
		value = value,
		setret = true
	}
end

local function load(self)
	local handle = self:getHandle()

	local lines = handle and handle:content()
	if type(lines) == 'table' and getn(lines) ~= 0 then
		local response = { }

		for index, value in pairs(lines.props) do
			local path = self[index]
			path:rem 'default'

			response[#response + 1] = {
				path:set(value), index, value == path:get()
			}
		end

		return response
	end
end

local function getHandle(self)
	if not self.handle then
		local handle = self.storage:get(self.__name)
		if not handle then
			return nil, 'not path found'
		end

		if content:edit_dir(handle) then
			self.handle = content:newHandle(handle .. 'save.lua')
		end
	end

	return self.handle, self
end

return {
	save = save,
	load = load,
	getHandle = getHandle
}