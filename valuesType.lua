local values = {a={}, b={}}

function values:new()
	return setmetatable({a={}, b={}}, {__index=values})
end

function values:add(a)
	table.insert(self.a, a)
	self.b[a]=#self.a
	return self
end

function values:remove(a)
	self.b[self.a[a]]=nil
	self.a[a]=nil
	return self
end

function values:value(a)
	return self.a[a]
end

function values:index(a)
	return self.b[a]
end

function values:set(a, b)
	if self.a[a] then self.b[self.a[a]]=nil end
	self.a[a]=b
	self.b[b]=a
	return self
end

function values:size()
	return #self.a
end

return values