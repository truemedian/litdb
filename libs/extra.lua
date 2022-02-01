local slots = require 'core'

local format = string.format

local bad = 'Invalid argument #%s for %s (%s expected got %s)'
local warn = 'Expected %s for %s are %s (in %s)'

local namemt = {__tostring = function(self) return self.__string end}
local namefn = function(self, name)
	return setmetatable(
		{
			__string = self._path .. name,
			split = function(...)
				local val = select(1, ...)
				if val == 'path' then
					return name
				else
					return self.__string:split(...)
				end
			end
		},
		namemt
	)
end

local stores = {}

local function isStore(store)
	return stores[store]
end

local function getStoreSlot(self, name, channelInt)
	local type1, type2, type3 = type(self), type(name), type(channelInt)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'getStoreSlot', 'table', type1))
	elseif type2 ~= 'string' then
		return error(format(bad, 1, 'getStoreSlot', 'string', type2))
	elseif channelInt and type3 ~= 'number' and type3 ~= 'string' then
		return error(format(bad, 2, 'getStoreSlot', 'number', type2))
	end

	local channelId = self:getChannel(channelInt) or self._default_channel

	if not channelId then
		return nil, format(warn, 'value', 'channelId', 'nil', 'getSlotStore')
	end

	local mt = {
		client = self.client,
		_name = namefn(self, name),
		_channel_id = channelId,
		_threads = self._threads or {}
	}

	for name, fn in pairs(slots) do mt[name] = fn end
	mt = table.read(mt, true)

	stores[mt] = true
	return mt
end

return {
	isStore = isStore,
	getStoreSlot = getStoreSlot
}