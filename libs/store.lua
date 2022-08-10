local getn = require 'inspect'.getn
local content = require 'content'

local _handle = content:newHandle()

local function save(self)
	local handle = self:getHandle()
	if not handle then return nil end

	local value = {}

	for k, v in self.props.osean.iter() do
		update(k, v)
		value[k] = v
	end

	return handle:apply({
		key = 'props',
		value = value,
		setret = true
	})
end

local function load(self)
	local handle = self:getHandle()

	local content = handle and handle:content()
	content = content and (type(content) ~= 'table' or getn(content) == 0) and _handle:content()

	if type(content) == 'table' then
		local boat = self.props
		local response = { }

		for k, data in pairs(content) do
			for index, value in pairs(data) do
				response[#response + 1] = { boat:set(k, index, value), index, k }
			end
		end

		return response
	end
end

local function getHandle(self)
	if not self.handle then
		local handle = self.props:get('path', 'handle') or _handle:content().path.handle

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