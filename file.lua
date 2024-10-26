--- Class library based on Lua syntax sugar with omitting parentheses.
--
-- @author Er2 <er2@dismail.de>
-- @copyright 2022-2025
-- @license Zlib
-- @module Object

--[[lit-meta
	name = 'er2off/class'
	version = '1.0.0'
	homepage = 'https://github.com/er2off/lua-mods'
	description = 'Class library based on Lua syntax sugar with omitting parentheses.'
	tags = {'class', 'lua', 'oop'}
	license = 'Zlib'
	author = {
		name = 'Er2',
		email = 'er2@dismail.de'
	}
]]

local class, new

-- (Not) Virtual classes table
local vtable = {}

local Object = {
	__name = 'Object',
	__super = nil,
	__static = function() end,
	function() end,
}
Object.__index = Object
Object.__super = Object

--- Functions
-- @section Functions

--- Makes new class.
--
-- You can remove parentheses for class name because of Lua syntax sugar.
--
-- @tparam string name Class name.
-- @treturn Object Unfinished class generator table.
-- @raise If Object with same name already exists. (classes are global as for now)
-- @usage
-- class 'Test' : inherits 'BaseTest' {
--   function(this, ...)
--     this:super()
--     print(this, ...)
--   end
-- }
function class(name)
	assert(not vtable[name], 'Cannot override defined class '.. tostring(name))
	local o = setmetatable({
		__name = name,
		__tostring = Object.__tostring,
		--function() end,
	}, Object)
	o.__index = o
	vtable[name] = o
	return o
end

--- Creates new class instance.
--
-- You can remove parentheses for class name because of Lua syntax sugar.
--
-- @tparam string name Class name.
-- @treturn function Factory to construct class instances.
-- @raise If class wasn't found by name.
-- @usage
-- new 'Test' ()
-- new 'Test' {'somewhat', 'table'}
-- new 'Test' ('multiple', 'arguments')
-- new 'Test' 'Just string'
function new(name)
	local o = vtable[name]
	assert(o, 'Class '.. tostring(name) ..' does not exist')
	-- Find constructor
	local ctor = o[1]
	return function(...)
		-- Assign metamethods to empty table
		local t = setmetatable({}, o)
		-- Call constructor
		ctor(t, ...)
		return t
	end
end

_G.class = class
_G.new = new

--- Basic object metatable for classes.
-- @type Object

--- Marks this class as extending another.
-- @tparam string name Name of class which will be used as base.
-- @treturn Object Extended class copy.
-- @raise If class is already inherited from another.
function Object:inherits(name)
	-- Check for inheritance
	assert(self.__super, 'Class is already inherited to '.. self.__super.__name)
	-- Look up in vtable
	local o = vtable[name]
	assert(o, 'Class '.. tostring(name) ..' does not exist')
	return setmetatable(self, o:clone())
end

--- Makes clone of this class.
-- @treturn Object Cloned class.
function Object:clone()
	-- Clone all values
	local o = {}
	-- From base Object
	for k, v in pairs(Object)
	do o[k] = v end
	-- From user-defined
	for k, v in pairs(self)
	do o[k] = v end
	-- Assign meta-index and inheritance
	o.__index = o
	o.__super = self
	return setmetatable(o, self)
end

--- Calls method from parent class by its name.
-- @tparam string meth Method name.
-- @param ... params Parameters which will be passed to parent method.
function Object:superM(meth, ...)
	local o, fn = self
	-- lock to prevent class2:super() -> class1:super() -> class2:super() loop
	local lck = '__lock_'.. meth
	repeat o = o.__super
		fn = o[meth]
	until (fn or not o) and not o[lck]
	o[lck] = true
	-- don't raise error, should we?
	if not fn
	then return nil
	end
	local arg = {fn(self, ...)}
	o[lck] = nil
	return (table.unpack or unpack)(arg)
end

--- Calls parent constructor.
-- @param ... params Parameters which will be passed to parent method.
function Object:super(...)
	return self:superM(1, ...)
end

--- Metamethods
-- @section Metamethods

--- Transforms class to string.
--
-- Calls when using Lua tostring() function or when error occurs.
--
-- Prints only first 5 parents, others will be omitted.
-- @treturn string
function Object:__tostring()
	local str = 'Class "'.. self.__name ..'"'
	-- get some inherits to avoid long strings
	for _ = 1, 5 do
		self = self.__super
		if not self or self == Object
		then self = nil break end
		str = str.. ' <= "'.. self.__name ..'"'
	end
	if self then str = str.. '...' end
	return str
end

--- Call this to define class body.
-- @tparam table t table with all functions and variables
-- @usage
-- class 'Test' {
--   function()
--     print 'test'
--   end
-- } -- {...} is t
function Object:__call(t)
	-- override old values with new provided in table
	for k, v in pairs(t)
	do self[k] = v
	end
	-- start static constructor
	self:__static()
end
