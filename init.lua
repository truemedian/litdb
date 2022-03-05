
local assert, getmetatable, setmetatable, type, next 	= assert, getmetatable, setmetatable, type, next;
local table 											= table;
local table_insert, table_remove 						= table.insert, table.remove;
local CLASS, INSTANCE 									= 0, 1;
local root, class_api, instance_api 					= {}, {}, {};

local orcus 											= {
	MAX_CONSTRUCTOR_LINK 								= 1;
	_DESCRIPTION 										= 'object orientation implementation in Lua';
	_VERSION 											= 'v0.0.2';
	_URL 												= 'http://github.com/alphafantomu/orcus';
	_LICENSE 											= 'MIT LICENSE <http://www.opensource.org/licenses/mit-license.php>'
};

local deepCopy; deepCopy = function(t, base, deep)
	if (type(t) ~= 'table') then
		return t;
	end;
	local copy = base or {};
	for name, value in next, t do
		local t_value = type(value);
		copy[name] = copy[name] ~= value and t_value == 'table' and deep and deepCopy(value) or value;
	end;
	return copy;
end;

local isClass, isInstance = function(self)
	return getmetatable(self).__type == CLASS;
end, function(self)
	return getmetatable(self).__type == INSTANCE;
end;

local classToName = function(self)
	local t = type(self);
	local m = getmetatable(self);
	return t == 'table' and (self:isClass() and m.__name or self:isInstance() and m.__class.__name) or t == 'string' and self or nil;
end;

local getClassData = function(class)
	return type(class) == 'table' and class:isClass() and getmetatable(class) or nil;
end;

local isA = function(self, class)
	class = assert(type(self) == 'table' and classToName(class), 'class expected for comparison');
	local current_class = getmetatable((self:isInstance() and getmetatable(self).__class) or self);
	while (current_class) do
		if (current_class.__name == class) then
			return true;
		else current_class = getmetatable(current_class.__super);
		end;
	end;
	return false;
end;

local newClass = function(class_name, attributes, constructor, base_class)
	assert(base_class == nil or type(base_class) == 'table' and isClass(base_class), 'can only extend from a class');
	local class = setmetatable(deepCopy(class_api, nil, true),
	{
		__type = CLASS;
		__name = class_name;
		__constructor = constructor;
		__super = base_class;
		__mixins = {};

		__index = root.__index;
		__call = root.__call;
		__tostring = root.__tostring;
	});
	class.name, class.init = class_name, constructor;
	return class;
end;

local newInstance = function(self, a, b, c, d, e, f)
	assert(isClass(self), 'can only instantiate a class');
	local class_data = getmetatable(self);
	local constructor = self.init or class_data.__constructor or nil;
	local instance = setmetatable(deepCopy(instance_api, nil, true),
	{
		__type = INSTANCE;
		__class = self;

		__index = root.__index;
		__tostring = root.__tostring;
	});
	if (constructor) then
		for _ = 1, orcus.MAX_CONSTRUCTOR_LINK do
			constructor(instance, a, b, c, d, e, f);
			if (_ == 1) then
				a, b, c, d, e, f = nil, nil, nil, nil, nil, nil;
			end;
			local superclass = class_data.__super;
			if (superclass) then
				constructor = getmetatable(superclass).__constructor;
				if not (constructor) then
					break;
				end;
			else break;
			end;
		end;
	end;
	return instance;
end;

root.__call = function(self, a, b, c, d, e, f)
	return newInstance(self, a, b, c, d, e, f);
end;

root.__index = function(self, index)
	local meta = getmetatable(self);
	local ot = meta.__type;
	local reference = ot == INSTANCE and meta.__class or ot == CLASS and meta.__super or nil;
	--check mixins too
	if (reference) then
		local value = reference[index];
		if (value ~= nil) then
			rawset(self, index, value);
			return value;
		end;
	end;
end;

root.__tostring = function(self)
	local meta = getmetatable(self);
	local ot = meta.__type;
	local is_class, is_instance = ot == CLASS, ot == INSTANCE;
	return 'orcus '..(is_class and 'class' or is_instance and 'instance' or 'unknown')..' <'..(is_class and meta.__name or is_instance and getmetatable(meta.__class).__name or 'unknown')..'>';
end;

class_api.extend = function(self, class_name, attributes, constructor)
	return newClass(class_name, attributes, constructor, self);
end;

class_api.create = function(self, a, b, c, d, e, f)
	return newInstance(self, a, b, c, d, e, f);
end;

class_api.with = function(self, a, b, c, d, e, f) --actual class required
	local mixins = getmetatable(self).__mixins;
	local ma, mb, mc, md, me, mf = getClassData(a), getClassData(b), getClassData(c), getClassData(d), getClassData(e), getClassData(f);
	if (ma) then
		table_insert(mixins, a);
	end; if (mb) then
		table_insert(mixins, b);
	end; if (mc) then
		table_insert(mixins, c);
	end; if (md) then
		table_insert(mixins, d);
	end; if (me) then
		table_insert(mixins, e);
	end; if (mf) then
		table_insert(mixins, f);
	end;
end;

class_api.without = function(self, class)
	class = classToName(class);
	if (class) then
		local mixins = getmetatable(self).__mixins;
		for i = 1, #mixins do
			if (getmetatable(mixins[i]).__name == class) then
				table_remove(mixins, i);
				break;
			end;
		end;
	end;
end;

class_api.includes = function(self, class)
	class = classToName(class);
	if (class) then
		local mixins = getmetatable(self).__mixins;
		for i = 1, #mixins do
			if (getmetatable(mixins[i]).__name == class) then
				return true;
			end;
		end;
	end;
	return false;
end;

instance_api.cast = function(self, class)
	if (class) then
		local m = getmetatable(self);
		m.__class = class;
		--check for casting function?
	end;
end;

class_api.isClass, class_api.isInstance, class_api.isA = isClass, isInstance, isA;
instance_api.isClass, instance_api.isInstance, instance_api.isA = isClass, isInstance, isA;

return setmetatable(orcus, {__call = function(_, a, b, c, d) return newClass(a, b, c, d); end});