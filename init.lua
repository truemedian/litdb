local point, props, store = require 'point', require 'props', require 'store'

local bestore = {
	auto_save = true
}
store.props = props

-- Implement error detection

function bestore:load(...)
	return store:load(...)
end

function bestore:save(...)
	return store:save(...)
end

local defaults = {
	path = {
		handle = 'deps/bestore/handles/', ['store{}'] = 'deps/bestore/saves/'
	}
}

return setmetatable(bestore, {
	__call = function(self)
		self:load()
		
		for container, v in pairs(defaults) do
			for key, path in pairs(v) do
				self.props:set(container, key, path)
			end
		end

		for name, fn in next, point do
			self[name] = fn
		end
		
		if self.auto_save then self:save() end; return self
	end,
	__index = { props = props }
})