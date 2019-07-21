local Dict = {}
Dict.__index = Dict

function Dict.new()
	local self = setmetatable({}, Dict)
	self._dict = {}
	return self
 end

function Dict:set(key, value)
	self._dict[key] = value
end

function Dict:get(key)
	return self._dict[key]
end

function Dict:inc(key, value)
	local dict = self._dict
	if dict[key] == nil then
		dict[key] = 0
	end
	dict[key] = dict[key] + value
	return dict[key]
end

function Dict:values()
	local ret = {}
	for k, v in pairs(self._dict) do
		ret[k] = v
	end
	return ret
end

return {
	Dict = Dict
}
