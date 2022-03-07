
local require, type, assert = require, type, assert;

local getter = require('orcus')('getter', nil, function(self, method)
	if (method) then
		self:setMethod(method);
	end;
end);

getter.call = function(self, instance)
	local method = self.method;
	if not (type(method) == 'function') then
		self.method, method = nil, nil;
	end;
	assert(method, 'getter method not set')(instance);
end;

getter.setMethod = function(self, method)
	assert(type(method) == 'function', 'getter method is not a function');
	self.method = method;
end;

return getter;