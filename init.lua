local json = require 'json'
local decode, encode = json.decode, json.encode

local typeof, open, close = io.type, io.open, io.close

require 'lua-extensions'()

local format, sfind, split, lower = string.format, string.find, string.split, string.lower
local find, getn, sinsert, search = table.find, table.getn, table.sinsert, table.search

local execute, rm = os.execute, os.remove

local error_format = 'Incorrect argument #%s for %s (%s expected got %s)'

--- Check if the givened `name` is a existing file, the `extention` is optional.
--- The default is json.
---@param name string
---@param extention? string
---@return boolean
local function isExisting(name, extention)
	local type1, type2 = type(name), type(extention)
	if type1 ~= 'string' then
		return nil, format(error_format, 1, 'isExisting', 'string', type1)
	elseif extention and type2 ~= 'string' then
		return nil, format(error_format, 2, 'isExisting', 'string', type2)
	end

	local file = name .. (extention or '.json')
	return typeof(file) and true or open(file) and true or nil
end

--- Check if the givened `name` is a currently open file.
---@param name string
---@param extention? string
---@return boolean
local function isOpen(name, extention)
	local type1, type2 = type(name), type(extention)
	if type1 ~= 'string' then
		return nil, format(error_format, 1, 'isOpen', 'string', type1)
	elseif extention and type2 ~= 'string' then
		return nil, format(error_format, 2, 'isOpen', 'string', type2)
	end

	if isExisting(name, extention) then
		local file = typeof(name .. (extention or '.json'))
		if file and file ~= 'closed file' then
			return true
		else
			return nil
		end
	else
		return nil, 'File not exist.'
	end
end

--- Check if the givened `string` is json file, a lua file.
---@param string string
---@return boolean
---@return boolean
local function strip_type(string)
	return sfind(string, '%json$', 1) and true, sfind(string, '%lua$', 1) and true
end

--- Creates a path (of folders) with the givened `path`.
--- The last '/' are not taked, recognize it as the file.
---@param path string
local function createPath(path)
	local split, v = split(path, '/'), '.'

	for n, name in pairs(split) do
		if type(name) == 'string' then
			if name ~= '.' and n ~= getn(split) then
				v = v .. '\\' .. name
			end
		end
	end

	if #v > 1 then
		local test = open(v .. '\\test', 'w')

		if not test then
			execute('mkdir ' .. v)
		else
			close(test); rm(v .. '\\test')
		end
	end
end

--- The parameter `module` are explicit needed for create/import a file.
--- You can pass the key for apply a `index` in table value, if it is a `table`.
--- If `value` are not a table, only uses it as value writer.
--- If there no key and value are a table and are no scope,
--- then procced to apply to the next index in table exactly like: `#table + 1`.
---@param module string
---@param key? any
---@param value? any
---@param scope? string
---@param notmakepath? boolean
---@return boolean : code
local function apply(module, key, value, scope, notmakepath)
	local type1, type4 = type(module), type(scope)
	if type1 ~= 'string' then
		return nil, format(error_format, 1, 'apply', 'string', type1)
	elseif scope and type4 ~= 'string' then
		return nil, format(error_format, 4, 'apply', 'string', type4)
	end

	local isjson, islua = strip_type(module)

	if not islua and not isjson then
		module = module .. '.json'
	end

	if not notmakepath and scope ~= 'break' and not isExisting(module) then
		createPath(module)
	end

	local file = typeof(module) and module or open(module)

	if file then
		close(file)

		local o = open(module, 'r')
		local master = o and decode(o:read() or 'null')

		if master then
			if type(master) == 'table' then
				if key then
					local response = type(key) == 'string' and sinsert(master, key, value)

					if not response then
						master[key] = value
					end
				else
					if not scope then
						--if not find(master, value) then
							master[#master + 1] = value
						--end
					else
						master = value
					end
				end
			else
				master = value
			end
		else
			master = value

			if key then
				master = { [key] = value }
			end
		end

		file = open(module, 'w'):write(encode(master))

		close(file)
		return true
	elseif scope then
		if lower(scope) == 'module' and not isExisting(module) then
			open(module, 'w')

			if file then
				close(file)
			end

			return apply(module, key, value, 'break')
		elseif scope == 'break' then
			return nil, 'The function was breaked.'
		else
			return nil, 'Givened scope are nil or invalid.'
		end
	end
end

--- The parameter `module` are explicit needed for create/import a file.
--- If you give `scope` module, then tries to remove the module.
---
--- If you give any key as removal tries to set the scope but not recommended.
---@param module string
---@param key? any
---@param scope? string
---@return boolean : code
local function remove(module, key, scope)
	local type1, type3 = type(module), type(scope)
	if type1 ~= 'string' then
		return nil, format(error_format, 1, 'remove', 'string', type1)
	elseif scope and type3 ~= 'string' then
		return nil, format(error_format, 3, 'remove', 'stirng', type3)
	elseif not strip_type(module) then
		return nil, 'Module must be a json file.'
	end

	local file = typeof(module) and module or open(module)

	if file then
		if scope and lower(scope) == 'module' and isExisting(module) then
			local sucess, error = rm(module) -- pcall(rm, module .. etc)
			if sucess and not error then
				return true
			else
				return nil, error
			end
		end

		local reader = file:read()

		local value = decode(reader or 'null')

		if type(value) == 'table' then
			if type(key) == 'string' and not sinsert(value, key, scope or 'remove') then
				value[key] = scope or nil
			else
				value[key] = scope or nil
			end
		end

		file = open(module, 'w'):write(encode(value))

		close(file);

		return true
	else
		return nil, 'Invalid module/directory.'
	end
end

--- If there any `index` for search, then tries to return it.
--- Only if the file has a table into it.
---
--- Nothing passed: return the entire file content.
---@param module string
---@param index? any
---@return any
local function searchFor(module, index)
	local type1 = type(module)
	if type1 ~= 'string' then
		return nil, format(error_format, 1, 'searchFor', 'string', type1)
	elseif not strip_type(module) then
		return nil, 'Module must be a json file.'
	end

	local file = typeof(module) and module or open(module)
	if file then

		local value = decode(file:read() or 'null')

		if index and type(value) == 'table' then
			local sucess, thing = pcall(search, value, index)

			return value[index] or sucess and thing or nil
		else
			return value
		end
	end

	return nil, 'Invalid file/module.'
end


return {
	isExisting = isExisting,
	isOpen = isOpen,
	stype = strip_type,
	createPath = createPath,
	apply = apply,
	remove = remove,
	searchFor = searchFor
}