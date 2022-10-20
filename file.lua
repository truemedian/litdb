--[[lit-meta
	name = "alphafantomu/lua-emitter"
    version = "0.0.3"
    description = "event emitter in Lua with basic functionality"
    tags = { "event", "luvit", "lua" }
    license = "MIT"
    author = { name = "Ari Kumikaeru"}
    homepage = "https://github.com/alphafantomu/lua-emitter"
    dependencies = {"alphafantomu/orcus"}
    files = {"**.lua"}
]]

local require, assert, tostring, type = require, assert, tostring, type;
local table = table;
local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort;

---@class EventEmitter : OrcusClass
---@field _events table
---@field _maxListeners integer
---A event emitter class meant to handle registering and removal of events and callbacks
local emitter = require('orcus')('EventEmitter', {
	_events = {};
	_maxListeners = -1;
}, function(self, max_listeners)
	self._maxListeners = max_listeners or self._maxListeners or -1;
end);

local _sortWeight = function(a, b)
	return a[2] > b[2];
end;

local _has = function(self, event_name, callback)
	local callbacks = self._events[event_name];
	if (callbacks ~= nil) then
		local max_listeners = self._maxListeners;
		max_listeners = max_listeners == -1 and #callbacks or max_listeners;
		for i = 1, max_listeners do
			local data = callbacks[i];
			if (data) then
				if (data[1] == callback) then
					return true, i;
				end;
			else break;
			end;
		end;
	end;
	return false;
end;

---@param event_name string
---@param callback function
---@param weight? number
---@return EventEmitter
---Creates an event with the specified callback
emitter.on = function(self, event_name, callback, weight)
	weight = weight or 1;
	local events, max_listeners = self._events, self._maxListeners;
	local callbacks = events[event_name];
	local callback_address = tostring(callback);
	assert(type(callback) == 'function', callback_address..' is not a function');
	if not (callbacks) then
		callbacks = {};
		events[event_name] = callbacks;
	end;
	assert(max_listeners == -1 or (#callbacks < max_listeners), 'Max listeners ('..tostring(max_listeners)..') for event "'..event_name..'" is reached!');
	assert(not _has(self, event_name, callback), 'Event "'..tostring(event_name)..'" already has the callback '..callback_address..'.');
	table_insert(callbacks, {callback, weight});
	table_sort(callbacks, _sortWeight);
	return self;
end;

---@param event_name string
---@param callback function
---@param weight? number
---@return EventEmitter
---Creates an event with the specified callback for the first call, afterward it is removed
emitter.once = function(self, event_name, callback, weight)
	weight = weight or 1;
	local once_callback; once_callback = function(arg_a, arg_b, arg_c, arg_d, arg_e, arg_f)
		self:off(event_name, once_callback);
		return callback(arg_a, arg_b, arg_c, arg_d, arg_e, arg_f);
	end;
	return self:on(event_name, once_callback, weight);
end;

---@param event_name string
---@param callback function
---@return EventEmitter
---Removes an event with the specified callback
emitter.off = function(self, event_name, callback)
	local has, i = _has(self, event_name, callback);
	if (has) then
		table_remove(self._events[event_name], i);
		--self:off(event_name, callback);
	end;
	return self;
end;

---@param event_name string
---@return EventEmitter
---Fires the event with the specified `event_name`
emitter.emit = function(self, event_name, arg_a, arg_b, arg_c, arg_d, arg_e, arg_f)
	local callbacks = self._events[event_name];
	if (callbacks) then
		local max_listeners = self._maxListeners;
		max_listeners = max_listeners == -1 and #callbacks or max_listeners;
		for i = 1, max_listeners do
			local custom = callbacks[i];
			if (custom) then
				custom[1](arg_a, arg_b, arg_c, arg_d, arg_e, arg_f);
			else break;
			end;
		end;
	end;
	return self;
end;

---Clears all events specific to the emitter
emitter.clear = function(self)
	self._events = {};
end;

return emitter;