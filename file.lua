--[[lit-meta
	name = "alphafantomu/orcus-getter"
	version = "0.0.2"
	description = "a orcus extension for getter attributes in classes"
	tags = {"oop", "lua", "luvit", "extension"}
	license = "MIT"
	author = {name = "Ari Kumikaeru"}
	homepage = "https://github.com/alphafantomu/orcus-getter"
	dependencies = {'alphafantomu/orcus'}
	files = {"**.lua"}
]]
local require, type, assert = require, type, assert;

local getter = require('orcus')('getter');

getter.init = function(self, method)
	if (method) then
		self:setMethod(method);
	end;
end;

getter.call = function(self, instance)
	local method = self.method;
	if (not type(method) == 'function') then
		self.method, method = nil, nil;
	end;
	return assert(method, 'getter method not set')(instance);
end;

getter.setMethod = function(self, method)
	assert(type(method) == 'function', 'getter method is not a function');
	self.method = method;
end;

return getter;