
--[[lit-meta
	name = "alphafantomu/kagura-mea"
    version = "0.0.3"
    description = "A lightweight async function binder meant to mimick libuv async functions"
    tags = { "luvit", "reference", "async", "callbacks", "lua", "work", "thread" }
    license = "MIT"
    author = { name = "Ari Kumikaeru"}
    homepage = "https://github.com/alphafantomu/kagura-mea"
    files = {"**.lua"}
]]

local require, type = require, type;

local uv = require('uv');

local getCallback = function(a, b, c, d, e, f)
	return type(f) == 'function' and f
		or type(e) == 'function' and e
		or type(d) == 'function' and d
		or type(c) == 'function' and c
		or type(b) == 'function' and b
		or type(a) == 'function' and a
		or nil;
end;

---@param fx function the synchronous function to wrap around
---@return function AsyncFx the asynchronous version of `fx` as a wrapper
---Wraps `fx` as a thread based asynchronous function, there is a 6 argument limit on functions.
---
---In order to call the function asynchronously, pass a callback function at the end of the arguments, note that this will create a new thread. Otherwise the function runs synchronously.
local thread_async = function(fx)
	return function(a, b, c, d, e, f)
		local callback = getCallback(a, b, c, d, e, f);
		local ta, tb, tc, td, te, tf = type(a), type(b), type(c), type(d), type(e), type(f);
		a, b, c, d, e, f =
			ta ~= 'function' and a or nil,
			tb ~= 'function' and b or nil,
			tc ~= 'function' and c or nil,
			td ~= 'function' and d or nil,
			te ~= 'function' and e or nil,
			tf ~= 'function' and f or nil;
		if (callback) then
			local async_handler; async_handler = uv.new_async(function(ca, cb, cc, cd, ce, cf)
				callback(ca, cb, cc, cd, ce, cf);
				async_handler:close();
			end);
			uv.new_thread(fx, async_handler, a, b, c, d, e, f);
		else fx(a, b, c, d, e, f);
		end;
	end;
end;

---@param fx function the synchronous function to wrap around
---@return function AsyncFx the asynchronous version of `fx` as a wrapper
---Wraps `fx` as a thread-pool based asynchronous function, there is a 6 argument limit on functions.
---
---In order to call the function asynchronously, pass a callback function at the end of the arguments. Otherwise the function runs synchronously.
local async = function(fx)
	return function(a, b, c, d, e, f)
		local callback = getCallback(a, b, c, d, e, f);
		local ta, tb, tc, td, te, tf = type(a), type(b), type(c), type(d), type(e), type(f);
		a, b, c, d, e, f =
			ta ~= 'function' and a or nil,
			tb ~= 'function' and b or nil,
			tc ~= 'function' and c or nil,
			td ~= 'function' and d or nil,
			te ~= 'function' and e or nil,
			tf ~= 'function' and f or nil;
		if (callback) then
			local async_handler; async_handler = uv.new_async(function(ca, cb, cc, cd, ce, cf)
				callback(ca, cb, cc, cd, ce, cf);
				async_handler:close();
			end);
			uv.new_work(fx, function(...)
				async_handler:send(...);
			end):queue(a, b, c, d, e, f);
		else fx(a, b, c, d, e, f);
		end;
	end;
end;

return {
	thread_async = thread_async;
	async = async;
};