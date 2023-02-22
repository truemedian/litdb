--[[lit-meta
	name = 'Corotyest/content'
	version = '1.0.1'
	dependencies = { 'Corotyest/lua-extensions', 'Corotyest/inspect' }
]]

-- Semi-Rework. Next to generate a documentation.

local inspect = require 'inspect'
local extensions = require 'lua-extensions' ()
local string, table = extensions.string or string, extensions.table or table

local remove, execute = os.remove, os.execute
local concat, sinsert = table.concat, table.sinsert
local getudata, setudata = debug.getuservalue, debug.setuservalue
local typeof, open, close = io.type, io.open, io.close
local format, sfind, match, _split = string.format, string.find, string.match, string.split

local arg = 'incorrect argument #%s for %s (%s expected got %s)'
local request = '%s%srequest'

local haswindows = jit and jit.arch == 'Windows' or package.path:match('\\') and true
local prefix = haswindows and '\\' or '/'

local function split(value)
	local type1 = type(value)
	if type1 ~= 'string' then
		return nil, format(arg, 1, 'split', 'string', type1)
	end

	-- different matchs for get correct values
	local path = sfind(value, '/', 1, true); path = path and path ~= 1 and match(value, '(.*)/.*$') or nil
	local filename = path and match(value, '.*/(.-)$') or value

	return path and match(path, '%g*'), filename, match(filename, '.*%.(.-)$')
end

local function attach(path, ...)
	local type1 = type(path)
	if type1 ~= 'string' then
		return nil, format(arg, 1, 'attach', 'string', type1)
	end

	local has = sfind(path, '/', 1, true) ~= 1
	path = has and concat(_split(path, '/'), prefix) or path

	local response = { path }
	if ... then
		for index = 1, select('#', ...) do
			response[#response + 1] = select(index, ...)
		end
	end

	return concat(response, prefix)
end

local function editDir(self, path, deldir)
	local type1, type2 , type3 = type(self), type(path), type(deldir)
	if type1 ~= 'table' then
		return nil, format(arg, 'self', 'editDir', type1)
	elseif type2 ~= 'string' then
		return nil, format(arg, 1, 'editDir', 'string', type2)
	elseif deldir and type3 ~= 'boolean' then
		return nil, format(arg, 2, 'editDir', 'boolean', type3)
	end

	local path = attach(path)

	if path and #path ~= 0 then
		local endpoint = format(request, path, prefix)
		local response = open(endpoint, 'w')

		if not response then
			return execute(format('mkdir %s', path)) and true, 'new'
		else
			close(response); remove(endpoint)
			return deldir and execute(format('rmdir %s', path)) or not deldir and true, 'del'
		end
	end
end

local function isFile(file)
	local type1 = type(file)
	if type1 ~= 'userdata' then
		return false
	end

	return typeof(file) ~= nil or sfind(tostring(file), 'file', 1, true) == 1
end

local function setFileInfo(file, data)
	local type1 = type(file)
	if not isFile(file) then
		return nil, format(arg, 1, 'setFileInfo', 'userdata', type1)
	end

	data = type(data) == 'table' and data or { __name = data }

	local userdata = getudata(file)

	for key, value in pairs(data) do
		if sfind(key, '__', 1, true) ~= 1 then
			error('cannot damage userdata integrity')
		end
		userdata[key] = value
	end

	return setudata(file, userdata, '__index')
end

local handles = { }

local function openFile(self, filename)
	filename = filename or self.filename

    local input = open(filename, 'r')
	if not input and open(filename, 'w') then
		input = open(filename, 'r')
	end

	setFileInfo(input, filename)

	self.handle.input = input
	self.handle.output = {
		write = function(self, ...)
			local file = open(filename, 'w')
			local success, error = pcall(file.write, file, ...)

			if success then
				file:close()
				return success
			else
				return nil, error
			end
		end,
		__name = filename
	}

	return self
end

local function close(self)
	return self.handle.input:close()
end

local function reboot(self)
	if self.close and self:close() then
		return self:open()
	end
end

local function content(self, ...)
	local file = self.handle.input

	local lines = { }
	for line in file:lines() do
		lines[#lines + 1] = line
	end

	local data = concat(lines, '\n')
	local success, chunck = pcall(load(data, file.__name, nil, _G), ...)

	self:reboot()

	return success and chunck or data
end

local function write(self, options, ...)
	local file = self.handle.output

	local type1 = type(options)
	local setret = type1 == 'table' and options.setret

	local base = {...}
	if type1 ~= 'table' then table.insert(base, 1, options) end

	return file:write(self.extension == 'lua' and setret and 'return ' or '', unpack(base))
end

local function apply(self, options)
	local key, value = options.key, options.value

	local module = self:content()

	if type(module) == 'table' then
		if key then
			local response = type(key) == 'string' and sinsert(module, key, value)

			if not response then
				module[key] = value
			end
		else
			module[#module + 1] = value
		end
	else
		module = key and { [key] = value } or value
	end

	return self:write(options, inspect.encode(module))
end

local function delete(self)
	local filename = self.filename

	local success = self:close()
	if not success then
		return nil
	end

	handles[self] = nil

	return remove(filename)
end

local function newHandle(self, file)
	local type1, type2 = type(self), type(file)
	if type1 ~= 'table' then
		return nil, format(arg, 'self', 'neHandle', 'table', type1)
	elseif type2 ~= 'string' then
		if not self.isFile(file) then
			return nil, format(arg, 1, 'newHandle', 'string/userdata', type2)
		end
	end

	local pathname, filename, extension = self.split(file)

	if extension ~= 'lua' then
		return error('currently only supporting lua files', 2)
	end

	local meta = { }

	local props = {
		handle = { },
		pathname = pathname,
		filename = pathname and (pathname .. self.prefix .. filename) or filename,
		extension = extension,
		-- Functions
		open = openFile,
		close = close,
		apply = apply,
		write = write,
		delete = delete,
		reboot = reboot,
		content = content,
	}

	function meta.__pairs()
		local index, value
		return function()
			index, value = next(props, index)
			return index, value
		end
	end

	function meta:__index(key)
		if not handles[self] then
			return error('this handle is removed', 2)
		end

		local value = props[key]

		if type(value) ~= 'function' then
			return value
		else
			return function(self, ...)
				local type1 = type(self)
				if type1 ~= 'table' then
					return nil, format(arg, 'self', key, 'table', type1)
				end

				return value(self, ...)
			end
		end
	end

	function meta:__newindex(key, value)
		if self[key] then
			return error('attempt to overwrite a protected value', 2)
		end

		props[key] = value
	end

	function meta:__tostring()
		return self.filename
	end

	local handle = setmetatable({}, meta)

	handles[handle] = true
	return handle:open()
end

local function isHandle(handle)
	return handles[handle] == true
end

return {
	split = split,
	attach = attach,
	isFile = isFile,
	prefix = prefix,
	editDir = editDir, edit_dir = editDir,
	isHandle = isHandle,
	newHandle = newHandle,

	haswindows = haswindows,
	setFileInfo = setFileInfo,
}