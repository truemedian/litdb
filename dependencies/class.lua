local class = {};

function class.new(name,methods)
	local object = {};
	local logger = require("./logger");
	local timer = require("timer");
    local memoryLocation = tostring(object):gsub("table: ","");

	for key,method in pairs(methods) do 
		object[key] = method;
	end

	setmetatable(object,{
		__newindex = function(t,k)
			logger:log(1,"Attempted to modify a readonly table!");
		end,
		__metatable = "Protected";
		__tostring = function()
			return string.format(name.." "..memoryLocation);
		end
	})

	return object;
end

return class;