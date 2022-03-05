
local require, assert, tostring, type = require, assert, tostring, type;
local table = table;
local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort;

local emitter = require('orcus')('EventEmitter', nil, function(self, max_listeners)
	self._events = {};
	self._maxListeners = max_listeners or 10;
end);

local _sortWeight = function(a, b)
	return a[2] > b[2];
end;

local _has = function(self, event_name, callback)
	local max_listeners = self._maxListeners;
	local callbacks = self._events[event_name];
	if (callbacks ~= nil) then
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
	assert(#callbacks < max_listeners, 'Max listeners ('..tostring(max_listeners)..') for event "'..event_name..'" is reached!');
	assert(not _has(self, event_name, callback), 'Event "'..event_name..'" already has the callback '..callback_address..'.');
	table_insert(callbacks, {callback, weight});
	table_sort(callbacks, _sortWeight);
	return self;
end;

emitter.once = function(self, event_name, callback, weight)
	weight = weight or 1;
	local once_callback; once_callback = function(arg_a, arg_b, arg_c, arg_d, arg_e, arg_f)
		self:off(event_name, once_callback);
		return callback(arg_a, arg_b, arg_c, arg_d, arg_e, arg_f);
	end;
	return self:on(event_name, once_callback, weight);
end;

emitter.off = function(self, event_name, callback)
	local has, i = _has(self, event_name, callback);
	if (has) then
		table_remove(self._events[event_name], i);
		self:off(event_name, callback);
	end;
	return self;
end;

emitter.emit = function(self, event_name, arg_a, arg_b, arg_c, arg_d, arg_e, arg_f)
	local max_listeners = self._maxListeners;
	local callbacks = self._events[event_name];
	if (callbacks) then
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

emitter.clear = function(self)
	self._events = {};
end;

return emitter;