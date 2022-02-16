local json = require 'json'

local overwrite = require 'content'
local sf, set, rem = overwrite.searchFor, overwrite.apply, overwrite.remove

local insert, find, tset, getn = table.insert, table.find, table.set, table.getn
local format, dump, sfind = string.format, string.dump, string.find
local create, yield, status, close, resume = coroutine.create, coroutine.yield, coroutine.status, coroutine.close, coroutine.resume

local default_errors = {
	bad = 'bad argument #%s for %s (%s expected got %s)',
	warning = 'Expected %s for %s are %s (in %s)'
}

local bad, warn = default_errors.bad, default_errors.warning

local function encode(table, _in)
	local type1 = type(table)
	if type1 ~= 'table' then
		if type1 == 'function' then
			local fn = table

			return dump(fn, true)
		end

		return nil, format(bad, 1, 'encode', 'table', type1)
	end

	local response = _in and table or {}
	for key, value in pairs(table) do
		local typev = type(value)
		if typev == 'function' then
			local string = dump(value, true)

			response[key] = string
		elseif typev == 'table' and find(value, ':function') then
			local ret = encode(value)
			if ret then
				tset(response, key)
				for i, v in pairs(ret) do
					response[key][i] = v
				end
			end
		else
			response[key] = value
		end
	end

	return response
end

local function decode(table, env, _in)
	local type1 = type(table)
	if type1 ~= 'table' then
		if type1 == 'string' then
			local parse = json.decode(table)
			if type(parse) == 'table' then
				return decode(parse, env, _in)
			elseif type(parse) == 'string' then
				return parse:find('function') and load(parse, nil, nil, env) or parse
			end
		end

		return nil, format(bad, 1, 'decode', 'table', type1)
	end

	local response, errors = _in and table or {}, {}

	local nerror = 1
	for key, value in pairs(table) do
		local typev = type(value)
		if typev == 'string' then
			local fn = value:find('function') and load(value, nil, nil, env)
			response[key] = fn or value
		elseif typev == 'table' and find(value, '%string') then
			local ret, errors = decode(value, env)

			if ret then
				tset(response, key)

				for i, v in pairs(ret) do
					response[key][i] = v
				end
			else
				errors[tostring(key) .. '#' .. nerror] = errors
			end
		else
			response[key] = value
		end
	end
	return response, getn(errors) ~= 0 and errors or nil
end

local permissions = {'sendMessages', 'readMessages'}

local function getClientChannel(self, client, id)
	local type3 = type(id)
	if not self or not client or type3 ~= 'string' then
		return nil, 'Check args'
	end

	rawset(self, '_running_thread', create(function()
		local channel = client.get:getChannel(id)

		if not channel then
			return
		end

		local member = channel.guild:getMember(client.get.user.id)

		for _, perm in pairs(permissions) do
			if not member:hasPermission(channel, perm) then
				error('Client has not permission to ' .. perm, 2)
			end
		end

		yield(channel) -- wait for channel
	end))

	insert(self._threads, self._running_thread)

	return self._running_thread, #self._threads
end

local slots_cached = {}

local noclient = format(warn, 'value', 'client', '%q', '%q')
local nochannel = format(warn, 'value', 'channel', '%q', '%q')

--- Set a slot in the cloud with a identification key `id`, return error if it are.
---@param self table
---@param id string
---@param value any
---@return boolean
local function setSlot(self, id, value)
	local type1, type2 = type(self), type(id)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'setSlot', 'table', type1))
	elseif type2 ~= 'string' then
		return error(format(bad, 1, 'setSlot', 'string', type2))
	elseif not value then
		return error(format(bad, 2, 'setSlot', 'any', nil))
	end

	if self:getRunningThread() then
		return nil, 'Another thread already running'
	end

	local client, name = self.client, tostring(self._name)
	if not client then
		return nil, format(noclient, nil, name) .. ' for setSlot.'
	end

	local thread, _ = getClientChannel(self, client, self._channel_id)
	local sucess, channel = resume(thread)

	if sucess and channel then
		local messageId, _ = sf(name .. '.json', id)
		local store_value = encode(value) or value
		if not messageId then
			do self:quitSlot(id) end

			local content = json.encode(store_value)
			local message, error = channel:send(content)
			if message then
				local sucess, error = set(name .. '.json', id, message.id, 'module')
				if sucess then
					slots_cached[id] = value
				end
				return sucess, error
			end
			return nil, error, content
		else
			local message, _ = channel:getMessage(messageId)
			if message then
				local content = json.encode(store_value)
				local sucess, error = message:setContent(content)
				if sucess then
					slots_cached[id] = value
					return true
				else
					return nil, error, content
				end
			else
				return self:setSlot(id, value)
			end
		end
	end
	return nil, format(nochannel, type(channel), name) .. ' for setSlot.'
end

local geterr = 'Not founded data store in %s [, with id %s]'

--- Get a seted slot from the cloud, return error if it are.
---@param self table
---@param id string
---@param data? table
---@return boolean
local function getSlot(self, id, data)
	local type1, type2 = type(self), type(id)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'getSlot', 'table', type1))
	elseif type2 ~= 'string' then
		return error(format(bad, 1, 'getSlot', 'string', type2))
	end

	if self:getRunningThread() then
		return nil, 'Another thread already running'
	end

	if slots_cached[id] then
		return slots_cached[id]
	end

	local env, raw
	if type(data) == 'table' then
		env = rawget(data, '_env'); raw = rawget(data, 'jsonkraw')
	end

	local client, name = self.client, tostring(self._name)
	if not client then
		return nil, format(noclient, nil, name) .. ' for getSlot.'
	end

	local post, _ = getClientChannel(self, client, self._channel_id)
	local _, channel = resume(post)

	if channel then
		local messageId, _ = sf(name .. '.json', id)
		
		if messageId then
			local message, error = channel:getMessage(messageId)
			if message then
				local cont = message.content
				local dec, errs = decode(cont, env)
				return not raw and dec or cont, errs
			end

			return nil, error
		end

		self:quitSlot(id)

		return nil, format(geterr, name, id)
	end

	return nil, format(nochannel, type(channel), name) .. ' for getSlot.'
end

--- This function delete a slot from the cloud and return a error if it are.
---@param self table
---@param id string
---@return boolean
local function quitSlot(self, id)
	local type1, type2 = type(self), type(id)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'quitSlot', 'table', type1))
	elseif type2 ~= 'string' then
		return error(format(bad, 1, 'quitSlot', 'string', type2))
	end

	if self:getRunningThread() then
		return nil, 'Another thread already running'
	end

	local client, name = self.client, tostring(self._name)
	if not client then
		return nil, format(noclient, nil, name) .. ' for quitSlot.'
	end

	local unpost, _ = getClientChannel(self, client, self._channel_id)
	local sucess, channel = resume(unpost)

	if sucess and channel then
		local messageId, _ = sf(name .. '.json', id)
		if messageId then
			local data, error = channel:getMessage(messageId)
			if data then data:delete() end
			local srem, err = rem(name .. '.json', id)
			if srem then
				if slots_cached[id] then slots_cached[id] = nil end

				return true
			else
				return nil, err
			end

			return nil, error
		end

		return nil, format(geterr, name, id)
	end

	return nil, format(nochannel, type(channel), name) .. ' for quitSlot.'
end

local function escape(self, id)
	return self:quitSlot(id)
end

--- Uses the `quitSlot` base to delete all posible deletable objects, return table with possible errors.
---@param self table
---@return table?
local function quitAllSlots(self)
	local type1 = type(self)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'quitAllSlots', 'table', type1))
	end

	if self:getRunningThread() then
		return nil, 'Another thread already running'
	end

	local client, name = self.client, tostring(self._name)
	if not client then
		return nil, format(noclient, nil, name)
	end

	local module = sf(name .. '.json'); local errors = {}
	for id, messageId in pairs(module) do
		local sucess, error = pcall(escape, self, id)

		if not sucess then
			errors[#errors + 1] = error
		end
	end

	local nlen = getn(errors)
	return nlen == 0 and true or nil, nlen ~= 0 and errors
end

-- thread management (not very util)

--- Close a thread from table `self` located in `...[_threads]`.
---@param self table
---@param thread number
---@return boolean
local function closeThread(self, thread)
	local type1, type2 = type(self), type(thread)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'table', type1))
	elseif thread and type2 ~= 'number' then
		thread = tonumber(thread)
		if not thread then
			return error(format(bad, 1, 'number', type2))
		end
	end

	local thread = self._threads[thread]
	if thread then
		local sucess, error = close(thread)

		return sucess, error
	end
end

--- Clear all currently running threads or that may be closed, return a table with generated errors.
---@param self table
---@return table?
local function closeAllThreads(self)
	local type1 = type(self)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'table', type1))
	end

	local trds = self._threads
	if not trds then
		return nil, 'No currently seted thread(s).'
	end

	local errors = {}
	if trds ~= 0 then
		for n in ipairs(trds) do
			local s, e = self:closeThread(n)
			if not s then
				errors[n] = e
			end
		end
	end


	self._current_thread = self._current_thread and close(self._current_thread)

	local n = getn(errors)
	return n > 0 and errors
end

--- Returns the currently running thread from `self`.
---@param self table
---@param thread thread
---@return boolean
local function getRunningThread(self, thread)
	local type1, type2 = type(self), type(thread)
	if type1 ~= 'table' then
		return error(format(bad, 'self', 'table', type1))
	elseif thread and type2 ~= 'number' then
		return error(format(bad, 1, 'number', type2))
	end

	local trds = self._threads
	if not trds then
		return nil, 'No currently seted thread(s).'
	end

	local current = self._current_thread
	if current then
		local status = status(current)
		if status == 'running' then
			return true
		end
	end

	if getn(trds) ~= 0 then
		for _, thread in ipairs(trds) do
			local status = status(thread)
			if status == 'running' then
				return true
			end
		end
	end

	return nil, 'No active threads.'
end

local slots = {
	encode = encode,
	decode = decode,
	setSlot = setSlot,
	getSlot = getSlot,
	quitSlot = quitSlot,
	quitAllSlots = quitAllSlots,
	closeThread = closeThread,
	closeAllThreads = closeAllThreads,
	getRunningThread = getRunningThread,
}

return slots