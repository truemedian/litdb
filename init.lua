
local assert, getmetatable, setmetatable, type, next 	= assert, getmetatable, setmetatable, type, next;
local table 											= table;
local table_insert, table_remove 						= table.insert, table.remove;
local CLASS, INSTANCE 									= 0, 1;

local root = {};
---@class OrcusClassAPI
local class_api = {};
---@class OrcusInstanceAPI
local instance_api = {};

---@class orcus
---@field metamethod_emitter any
---@field fx_bind function|nil
---A class handler with external dependency capabilities
---
---You can find more information at [github](https://github.com/alphafantomu/orcus)
local orcus 											= {
	MAX_CONSTRUCTOR_LINK 								= 1;
	_DESCRIPTION 										= 'object orientation implementation in Lua';
	_VERSION 											= 'v0.0.5';
	_URL 												= 'http://github.com/alphafantomu/orcus';
	_LICENSE 											= 'MIT LICENSE <http://www.opensource.org/licenses/mit-license.php>'
};

---@class OrcusBase
---@class OrcusClass : OrcusBase, OrcusClassAPI
---@class OrcusInstance : OrcusClass, OrcusInstanceAPI

local deepCopy; deepCopy = function(t, base, deep)
	if (type(t) ~= 'table') then
		return t;
	end;
	local copy = base or {};
	local meta = getmetatable(t);
	for name, value in next, t do
		local t_value = type(value);
		copy[name] = copy[name] ~= value and t_value == 'table' and deep and deepCopy(value, nil, deep) or value;
	end;
	if (meta ~= nil and deep) then
		setmetatable(copy, deepCopy(meta, nil, deep));
	end;
	return copy;
end;

---@param self OrcusInstance|OrcusClass
---Determines if `self` is a class
local isClass = function(self)
	return getmetatable(self).__type == CLASS;
end

---@param self OrcusInstance|OrcusClass
---Determines if `self` is a instance
local isInstance = function(self)
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

---@param self OrcusInstance|OrcusClass
---@param class OrcusClass|string
---@return boolean isOfClass
---Determines if `self` is of `class`
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

local getSuperclasses = function(self)
	assert(isClass(self), 'class expected to initialize');
	local classes = {};
	local current_class = self;
	while (getmetatable(current_class)) do
		table_insert(classes, current_class);
		current_class = getmetatable(current_class).__super;
	end;
	return classes;
end;

local compressSuperAttributes; compressSuperAttributes = function(self, base, mixins)
	assert(isClass(self), 'class expected to initialize');
	local self_metatable = getmetatable(self);
	local superclasses = getSuperclasses(self);
	local __attributes = self_metatable.__attributes;
	local n = #superclasses;
	local compressed_attributes = __attributes and deepCopy(__attributes, base, true) or {};
	for i = n, 1, -1 do
		local class = superclasses[i];
		local class_metatable = getmetatable(class);
		local class__attributes = class_metatable.__attributes;
		if (class__attributes) then
			deepCopy(class__attributes, compressed_attributes, true);
		end;
	end;
	if (mixins) then
		local __mixins = self_metatable.__mixins;
		local ne = #__mixins;
		for i = 1, ne do
			local mixin_class = __mixins[i];
			compressed_attributes = compressSuperAttributes(mixin_class, compressed_attributes, true);
		end;
	end;
	return compressed_attributes;
end;

local newClass = function(class_name, attributes, constructor, base_class)
	assert(base_class == nil or type(base_class) == 'table' and isClass(base_class), 'can only extend from a class');
	local copy = deepCopy(attributes, nil, true);
	local class = setmetatable(deepCopy(class_api, copy, true),
	{
		__type = CLASS;
		__name = class_name;
		__constructor = constructor;
		__super = base_class;
		__mixins = {};
		__attributes = attributes;
		--__cast = nil; --for casting, self, casting class

		__index = root.__index;
		__call = root.__call;
		__tostring = root.__tostring;
	});
	class.name, class.init = class.name or class_name, constructor;
	return class;
end;

local newInstance = function(self, a, b, c, d, e, f)
	assert(isClass(self), 'can only instantiate a class');
	local class_data = getmetatable(self);
	local constructor = self.init or class_data.__constructor or nil;
	local instance = setmetatable(deepCopy(instance_api, compressSuperAttributes(self, nil, true), true),
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
	if (ot == INSTANCE) then
		local value = meta.__class[index];
		if (value ~= nil) then
			if (type(value) == 'table' and value.isA ~= nil and value:isA('getter')) then
				return value:call(self);
			else
				rawset(self, index, value);
				return value;
			end;
		end;
	elseif (ot == CLASS) then --class attributes do not trigger __index here
		--mixins -> superclasses
		local __mixins, __super = meta.__mixins, meta.__super;
		local n = #__mixins;
		for i = 1, n do
			local mixin_class = __mixins[i];
			local value = mixin_class[index];
			if (value ~= nil) then
				return value;
			end;
		end;
		if (__super ~= nil) then
			local value = __super[index];
			if (value ~= nil) then
				return value;
			end;
		end;
	end;
end;

root.__newindex = function(self, index, value)
	local metamethod_emitter, fx_bind = orcus.metamethod_emitter, orcus.fx_bind;
	if (metamethod_emitter and metamethod_emitter.isA ~= nil and metamethod_emitter:isA('EventEmitter')) then
		local meta = getmetatable(self);
		local ot = meta.__type;
		if (ot == INSTANCE) then
			metamethod_emitter:emit('__newindex', self, index, value);
		end;
	end;
	if (fx_bind) then
		rawset(self, index, fx_bind(value));
	end;
end;

root.__tostring = function(self)
	local meta = getmetatable(self);
	local ot = meta.__type;
	local is_class, is_instance = ot == CLASS, ot == INSTANCE;
	return 'orcus '..(is_class and 'class' or is_instance and 'instance' or 'unknown')..' <'..(is_class and meta.__name or is_instance and getmetatable(meta.__class).__name or 'unknown')..'>';
end;

---@param self OrcusClass
---@param class_name string
---@param attributes? table
---@param constructor? function
---Creates a subclass `OrcusClass` of the extended class with specified parameters
class_api.extend = function(self, class_name, attributes, constructor)
	return newClass(class_name, attributes, constructor, self);
end;

---@param self OrcusClass
---@return OrcusInstance
---Creates a new `OrcusInstance` based off of the `OrcusClass`, 6 arguments max for the constructor
class_api.create = function(self, a, b, c, d, e, f)
	return newInstance(self, a, b, c, d, e, f);
end;

---@param self OrcusClass
---Adds a class as a mixin for the `OrcusClass`, 6 arguments max for the constructor
class_api.with = function(self, a, b, c, d, e, f)
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

---@param self OrcusClass
---@param class OrcusClass|string
---Removes a class from `OrcusClass`'s mixin table
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

---@param self OrcusClass
---@param class OrcusClass|string
---@return boolean hasAsMixin
---Checks if the `OrcusClass` has the `class` as a mixin
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

---@param self OrcusClass
---@return string|nil
---Gets the class name of the class
class_api.getName = function(self)
	local m = getmetatable(self);
	if (m) then
		return m.__name;
	end;
end;

---@param self OrcusInstance
---@param class OrcusInstance|string
---Casts the instance of a class to `class`
instance_api.cast = function(self, class)
	if (class) then
		local m = getmetatable(self);
		local cc = m.__class;
		if (cc) then
			local cast_init = getmetatable(cc).__cast;
			if (cast_init) then
				cast_init(self, class);
			end;
		end;
		m.__class = class;
	end;
end;

---@param self OrcusInstance
---@return string|nil
---Gets the class name of the instance
instance_api.getName = function(self)
	local m = getmetatable(self);
	local cc = getmetatable(m.__class);
	if (cc) then
		return cc.__name;
	end;
end;

class_api.isClass, class_api.isInstance, class_api.isA = isClass, isInstance, isA;
instance_api.isClass, instance_api.isInstance, instance_api.isA = isClass, isInstance, isA;

return setmetatable(orcus, {__call = function(_, a, b, c, d) return newClass(a, b, c, d); end});