
-- Woohoo! Kagura Mea is awesome! :) --
local require, setmetatable, type, tostring, xpcall = require, setmetatable, type, tostring, xpcall;

local uv = require('uv');

local binds = setmetatable({}, {__mode = 'v'});

local linkValue = function(v)
	local tv = type(v);
	if (tv == 'function') then
		local address = tostring(v);
		binds[address] = v;
		v = address;
	end;
	return tv ~= 'table' and v;
end;

local linkValueToThread = function(v)
	return binds[v] or v;
end;

local getCallbackFromBinds = function(a, b, c, d, e, f)
	return binds[f] or binds[e] or binds[d] or binds[c] or binds[b] or binds[a];
end;

local getCallback = function(a, b, c, d, e, f)
	return type(f) == 'function' and f
		or type(e) == 'function' and e
		or type(d) == 'function' and d
		or type(c) == 'function' and c
		or type(b) == 'function' and b
		or type(a) == 'function' and a
		or nil;
end;

local clearBinds = function(a, b, c, d, e, f)
	if (binds[f]) then
		binds[f] = nil;
	end; if (binds[e]) then
		binds[e] = nil;
	end; if (binds[d]) then
		binds[d] = nil;
	end; if (binds[c]) then
		binds[c] = nil;
	end; if (binds[b]) then
		binds[b] = nil;
	end; if (binds[a]) then
		binds[a] = nil;
	end;
end;

local async = function(fx)
	local handler;
	handler = uv.new_async(function(a, b, c, d, e, f)
		local callback, err = getCallbackFromBinds(a, b, c, d, e, f);
		local aa, ab, ac, ad, ae, af = linkValueToThread(a), linkValueToThread(b), linkValueToThread(c), linkValueToThread(d), linkValueToThread(e), linkValueToThread(f);
		clearBinds(a, b, c, d, e, f);
		local res, ca, cb, cc, cd, ce, cf = xpcall(fx, function(s)
			err = 'async thread: '..s;
		end, aa, ab, ac, ad, ae, af);
		if (res) then
			callback(nil, ca, cb, cc, cd, ce, cf);
		else callback(err);
		end;
		handler:close();
	end);
	return function(a, b, c, d, e, f)
		local callback = getCallback(a, b, c, d, e, f);
		if (callback) then
			assert(handler:send(linkValue(a), linkValue(b), linkValue(c), linkValue(d), linkValue(e), linkValue(f)));
		else
			local err;
			local res, ca, cb, cc, cd, ce, cf = xpcall(fx, function(s)
				err = 'async thread: '..s;
			end, a, b, c, d, e, f);
			if (res) then
				return ca, cb, cc, cd, ce, cf;
			else return false, err;
			end;
		end;
	end;
end;

return async;