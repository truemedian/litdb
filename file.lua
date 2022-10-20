--[[lit-meta
	name = "alphafantomu/orcus"
    version = "0.0.7"
    description = "object oriented handler in lua"
    tags = { "lua", "luvit", "oop", "handler", "lightweight" }
    license = "MIT"
    author = { name = "Ari Kumikaeru"}
    homepage = "https://github.com/alphafantomu/orcus"
    files = {"**.lua"}
]]
local assert, getmetatable, setmetatable, type, next, rawget, rawset 	= assert, getmetatable, setmetatable, type, next, rawget, rawset;
local table 															= table;
local table_insert, table_remove 										= table.insert, table.remove;
local CLASS, INSTANCE 													= 0, 1;

local root = {};
---@class OrcusClassAPI
local class_api = {};
---@class OrcusInstanceAPI
local instance_api = {};

---@class orcus
--- A class handler with external dependency capabilities
---
---You can find more information at [github](https://github.com/alphafantomu/orcus)
local orcus 											= {
	MAX_CONSTRUCTOR_LINK 								= 1;
	_DESCRIPTION 										= 'object orientation implementation in Lua';
	_VERSION 											= 'v0.0.7';
	_URL 												= 'http://github.com/alphafantomu/orcus';
	_LICENSE 											= 'MIT LICENSE <http://www.opensource.org/licenses/mit-license.php>';
	extension = {
		getter_classname = 'getter';
		function_wrapper = nil;
		newindex_callback = nil;
	};
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
---@return string|nil
---Returns the class name of the class or instance
local getClassName = function(self)
	local meta = getmetatable(self);
	local ctype = meta.__type;
	return ctype == CLASS and meta.__name or ctype == INSTANCE and meta.__class.__name or nil;
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

---@param self OrcusInstance|OrcusClass
---@param class OrcusClass
---@return boolean isOfClass
---Determines if `self` is of `class`
local isA = function(self, class)
	local name = getClassName(class);
	local current_class = getmetatable((self:isInstance() and getmetatable(self).__class) or self);
	while (current_class) do
		if (current_class.__name == name) then
			return true;
		else current_class = getmetatable(current_class.__super);
		end;
	end;
	return false;
end;

local newClass = function(name, fields, constructor, base)
	fields = deepCopy(fields, nil, true) or {};
	fields.name = name;
	fields.init = constructor;
	return setmetatable({}, {
		__type = CLASS;
		__name = name;
		__constructor = constructor;
		__super = base;
		__mixins = {};
		__fields = deepCopy(fields, nil, true);
		__cast = nil;
		__settings = {
			superConstruct = false;
			withConstruct = false;
		};
		__index = root.__index;
		__newindex = root.__newindex;
		__call = root.__call;
		__tostring = root.__tostring;
	});
end;

local newInstance = function(class, ...)
	local meta = getmetatable(class);
	local super, mixins = meta.__super, meta.__mixins;
	local classname = meta.__name;
	local constructor = class.init or meta.__constructor;
	local n = #mixins;
	local fields_copy = deepCopy(meta.__fields, nil, true) or {};
	fields_copy.name = classname;
	local instance = setmetatable(fields_copy, {
		__type = INSTANCE;
		__class = class;
		__index = root.__index;
		__newindex = root.__newindex;
		__tostring = root.__tostring;
	});
	if (constructor) then
		constructor(instance, ...);
	end;
	while (super) do
		local super_meta = getmetatable(super);
		if (super_meta.__settings.superConstruct) then
			local super_constructor = super.init or super_meta.__constructor;
			if (super_constructor) then
				super_constructor(instance);
			end;
		end;
		super = super_meta.__super;
	end;
	if (n > 0) then
		for i = 1, n do
			local mixin = mixins[i];
			local mixin_meta = getmetatable(mixin);
			if (mixin_meta.__settings.withConstruct) then
				local mixin_constructor = mixin.init or mixin_meta.__constructor;
				if (mixin_constructor) then
					mixin_constructor(instance);
				end;
			end;
		end;
	end;
	return instance;
end;

root.__index = function(self, index)
	local meta = getmetatable(self);
	local ctype = meta.__type;
	local class, fields, mixins, super = meta.__class, meta.__fields, meta.__mixins, meta.__super;
	local value;
	if (value == nil) then
		if (ctype == INSTANCE) then
			value = instance_api[index];
		elseif (ctype == CLASS) then
			value = class_api[index];
		end;
	end;
	if (value == nil and class) then
		value = deepCopy(class[index], nil, true);
	end;
	if (value == nil and fields) then
		value = rawget(fields, index);
	end;
	if (value == nil and super) then
		value = deepCopy(super[index], nil, true);
	end;
	if (value == nil and mixins) then
		local n = #mixins;
		for i = 1, n do
			local proxy_value = mixins[i][index];
			if (proxy_value ~= nil) then
				value = proxy_value;
				break;
			end;
		end;
	end;
	local value_meta = getmetatable(value);
	if (type(value) == 'table' and value_meta and value_meta.__name and value_meta.__name ==  orcus.extension.getter_classname) then
		value = value:call(self);
	end;
	if (value ~= nil) then
		rawset(self, index, value);
	end;
	return value;
end;

root.__newindex = function(self, index, value)
	local meta = getmetatable(self);
	local ctype = meta.__type;
	local newindex_callback = orcus.extension.newindex_callback;
	local wrapper = orcus.extension.function_wrapper;
	if (wrapper and type(wrapper) == 'function') then
		--check if its already wrapped
		value = wrapper(value);
	end;
	rawset(ctype == INSTANCE and self or ctype == CLASS and meta.__fields or nil, index, value); ---@diagnostic disable-line
	if (newindex_callback) then
		newindex_callback(self, index, value);
	end;
end;

root.__call = function(self, ...)
	local meta = getmetatable(self);
	local ctype = meta.__type;
	assert(ctype == CLASS, 'cannot instantiate a instance');
	return newInstance(self, ...);
end;

root.__tostring = function(self)
	local meta = getmetatable(self);
	local name, classname = self.name, meta.__name or meta.__class.__name;
	local ctype = meta.__type;
	return 'Orcus '..(ctype == CLASS and 'Class ' or ctype == INSTANCE and 'Instance ')..(name ~= classname and '"'..(name or 'null')..'" ')..'<'..(classname or 'null')..'>';
end;

---@param self OrcusClass
---@param name string
---@param fields? table
---@param constructor? function
---Creates a subclass `OrcusClass` of the extended class with specified parameters
class_api.extend = function(self, name, fields, constructor)
	return newClass(name, fields, constructor, self);
end;

---@param self OrcusClass
---@return OrcusInstance
---Creates a new `OrcusInstance` based off of the `OrcusClass`, 6 arguments max for the constructor
class_api.create = function(self, ...)
	return newInstance(self, ...);
end;

---@param self OrcusClass
---Adds a class as a mixin for the `OrcusClass`
class_api.with = function(self, a, b, c, d, e, f)
	local mixins = getmetatable(self).__mixins;
	if (a) then
		table_insert(mixins, a);
	end; if (b) then
		table_insert(mixins, b);
	end; if (c) then
		table_insert(mixins, c);
	end; if (d) then
		table_insert(mixins, d);
	end; if (e) then
		table_insert(mixins, e);
	end; if (f) then
		table_insert(mixins, f);
	end;
end;

---@param self OrcusClass
---@param class OrcusClass
---Removes a class from `OrcusClass`'s mixin table
class_api.without = function(self, class)
	if (class) then
		local mixins = getmetatable(self).__mixins;
		for i = 1, #mixins do
			if (mixins[i] == class) then
				table_remove(mixins, i);
				break;
			end;
		end;
	end;
end;

---@param self OrcusClass
---@param class OrcusClass
---@return boolean hasAsMixin
---Checks if the `OrcusClass` has the `class` as a mixin
class_api.includes = function(self, class)
	if (class) then
		local mixins = getmetatable(self).__mixins;
		for i = 1, #mixins do
			if (mixins[i] == class) then
				return true;
			end;
		end;
	end;
	return false;
end;

---@param self OrcusInstance
---@param class OrcusInstance
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

class_api.getClassName, class_api.isClass, class_api.isInstance, class_api.isA = getClassName, isClass, isInstance, isA;
instance_api.getClassName, instance_api.isClass, instance_api.isInstance, instance_api.isA = getClassName, isClass, isInstance, isA;

return setmetatable(orcus, {
	__call = function(_, name, fields, constructor, base)
		return newClass(name, fields, constructor, base);
	end});