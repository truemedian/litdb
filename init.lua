local warn = print
local format = string.format

local meta = {}
---Table for every defined namespace
local namespaces = {}
---Table for every defined class
local names = {}
---Table for every class
local classes = {}
---Table for every class object created
local objects = setmetatable({}, {__mode = 'k'})

local function unhandledInit(name)
	return function(self,...)
		local ret = {}
		for i = 1, select('#', ...) do
			table.insert(ret, tostring(select(i, ...)))
		end
		warn("Unhandled init for "..name..": \n"..table.concat(ret, '\t'))
	end
end

function meta:__call(...)
	self.__init = self.__init or unhandledInit(self:getFullName())
	local obj = setmetatable({}, self)
	objects[obj] = true
	obj:__init(...)
	return obj
end

function meta:__tostring()
	return 'class ' .. self:getFullName()
end

local default = {}

function default:__tostring()
	return self:getFullName()
end

function default:__hash()
	return self
end

function default.getType(self)
	return self.__class
end

function default.getFullName(self)
	return self.__namespace .. '/' .. self.__name
end

---Checks if ``cls`` is a class
---@param cls table The class
---@return boolean
local function isClass(cls)
	return classes[cls]
end

---Checks if ``obj`` is a class object
---@param obj table The object
---@return boolean
local function isObject(obj)
	return objects[obj]
end

---Checks if ``sub`` is a subclass of ``cls``
---@param sub table The subclass
---@param cls table The class
---@return boolean
local function isSubclass(sub, cls)
	if isClass(sub) and isClass(cls) then
		if sub == cls then
			return true
		else
			for _, base in ipairs(sub.__bases) do
				if isSubclass(base, cls) then
					return true
				end
			end
		end
	end
	return false
end

---Checks if ``obj`` is an instance of ``cls``
---@param obj table The object
---@param cls table The class
---@return boolean
local function isInstance(obj, cls)
	return isObject(obj) and isSubclass(obj.__class, cls)
end

---Counts all objects for each class and returns a dictionary of object counts indexed by the class full name
---@return table profiles Dictionary of object counts by class full name
local function profile()
	local ret = setmetatable({}, {__index = function() return 0 end})
	for obj in pairs(objects) do
		local name = obj:getFullName()
		ret[name] = ret[name] + 1
	end
	return ret
end

local types = {['string'] = true, ['number'] = true, ['boolean'] = true}

local function _getPrimitive(v)
	return types[type(v)] and v or v ~= nil and tostring(v) or nil
end

---Turns a class object into a primitive table
---@param obj table
---@return table primitive
local function serialize(obj)
	if isObject(obj) then
		local ret = {}
		for k, v in pairs(obj.__getters) do
			ret[k] = _getPrimitive(v(obj))
		end
		return ret
	else
		return _getPrimitive(obj)
	end
end

local rawtype = type
---Returns the type of its only argument, coded as a string. The possible results of this function are `"nil"` (a string, not the value `nil`), `"number"`, `"string"`, `"boolean"`, `"table"`, `"function"`, `"thread"`, `"userdata"`, and the name of a `class`.
---@param v any
---@return type type
local function type(v)
	return isObject(v) and v:getFullName() or rawtype(v)
end

---@param namespace string
---@param name string
---@return table instance The created class instance
local class = function(namespace, name, ...)
end

---Create classes like this `class("Namespace", "ClassName", ... [bases])` => `ClassName` instance
local class = setmetatable({
	namespaces = namespaces,
	classes = names,
	isClass = isClass,
	isObject = isObject,
	isSubclass = isSubclass,
	isInstance = isInstance,
	type = type,
	profile = profile,
	serialize = serialize,

}, {__call = function(_, namespace, name, ...)

	if not namespaces[namespace] then
		namespaces[namespace] = {}
	end

	local _names = namespaces[namespace]
	if _names[name] then return error(format('Class %q already defined', namespace.."/"..name)) end

	local class = setmetatable({}, meta)
	classes[class] = true

	for k, v in pairs(default) do
		class[k] = v
	end

	local bases = {...}
	local getters = {}
	local setters = {}

	for k, v in pairs(default) do
		class[k] = v
	end

	for _, base in ipairs(bases) do
		for k1, v1 in pairs(base) do
			class[k1] = v1
			for k2, v2 in pairs(base.__getters) do
				getters[k2] = v2
			end
			for k2, v2 in pairs(base.__setters) do
				setters[k2] = v2
			end
		end
	end

	class.__name = name
	class.__namespace = namespace
	class.__class = class
	class.__bases = bases
	class.__getters = getters
	class.__setters = setters

	local pool = {}
	local n = #pool

	function class:__index(k)
		if getters[k] then
			return getters[k](self)
		elseif pool[k] then
			return rawget(self, pool[k])
		else
			return class[k]
		end
	end

	function class:__newindex(k, v)
		if setters[k] then
			return setters[k](self, v)
		elseif class[k] or getters[k] then
			return error(format('Cannot overwrite protected property: %s.%s', name, k))
		elseif k:find('_', 1, true) ~= 1 then
			return error(format('Cannot write property to object without leading underscore: %s.%s', name, k))
		else
			if not pool[k] then
				n = n + 1
				pool[k] = n
			end
			return rawset(self, pool[k], v)
		end
	end

	_names[name] = class
	names[namespace.."/"..name] = class

	return class, getters, setters

end})

return class