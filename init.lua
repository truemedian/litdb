-- Globals
local dad_b0x = {} do
	-- Environement
	dad_b0x.mainEnv = getfenv(); -- global env

	-- Pre-defined tables
	dad_b0x.Fake = {
		['Functions'] = {};
		['Instances'] = {};
	};

	-- Output related shananighans
	dad_b0x.printString = "";

	-- Internalized functions
	dad_b0x.internalFunctions = {
		['safe_tostring'] = (function(arg, count) -- thanks tusky
			count = count or 1;
			if (count > 10) then
				return error ('Stack overflow prevented, unsafe operator canceled', count);
			end;

			local s, m = pcall (tostring, arg) do
				if (not s) then
					return error ('Unable to cast to a string', count + 1);
				else
					if (type (m) ~= 'string') then
						return safe_tostring (m, count + 1);
					end;

					return m;
				end;
			end;
		end);
	};

	-- Environments
	dad_b0x.Environments = {
		['level_1'] = setmetatable({},{
			__index = (function(self,index)
				if dad_b0x.Blocked.Instances[index] then
					return nil;
				elseif dad_b0x.Blocked.Functions[index] then
					return dad_b0x.Blocked.Functions[index];
				elseif dad_b0x.Fake.Functions[index] then
					return dad_b0x.Fake.Functions[index];
				elseif dad_b0x.Fake.Instances[index] then
					return dad_b0x.Fake.Instances[index];
				else
					return dad_b0x.mainEnv[index];
				end
			end);

			__metatable = 'Locked. (level_1)';
		}),
	}

	-- Blocked functions
	dad_b0x.Blocked = {
		['Instances'] = {
			['io'] = true;
			['module'] = true;
		};

		['Functions'] = {
			['require'] = (function(...)
				return error('Attempt to call require() (action has been blocked)', 2)
			end);
			['collectgarbage'] = (function(...)
				return error('Attempt to call collectgarbage() (action has been blocked)', 2);
			end);
			['dofile'] = (function(...)
				return error('Attempt to call dofile() (action has been blocked)', 2);
			end);
			['loadfile'] = (function(...)
				return error('Attempt to call loadfile() (action has been blocked)', 2);
			end);
		}
	}

	dad_b0x.Fake = {
		['Functions'] = {
			['xpcall'] = (function (luaFunc, handler)
				if type(handler) ~= type(function() end) then
					return error('Bad argument to #1, \'value\' expected', 2);
				else
					local success_func = {pcall(luaFunc)};

					if not success_func[1] then
						local e,r = pcall(handler, success_func[2]);

						if not e then
							return false, 'error in handling';
						end
					end

					return unpack(success_func);
				end
			end);

			['wait'] = (function(seconds)
				if type(seconds) ~= "number" and not seconds == nil then
					return error(("bad argument #1 'wait' (number expected, got %s)"):format(type(seconds) or nil), 2);
				else
					local start = os.clock();
					repeat until os.clock() > start + (start / os.clock() / 25) or seconds;

					if seconds then
						return seconds;
					else
						return (start / os.clock() / 25);
					end
				end
			end);

			['getfenv'] = (function(flevel)
				local s,m = pcall(getfenv, flevel) do
					if not s then
						return error(m, 2);
					else
						if m == dad_b0x.mainEnv then
							return getfenv(0);
						else
							return m;
						end
					end
				end
			end);

			['setfenv'] = (function(f, env)
				local s,m = pcall(getfenv, f);
				if m then
					if m == dad_b0x.mainEnv then
						if type(f) == "function" then
							return error ("'setfenv' cannot change the environment of this function", 2);
						end

						return getfenv(0);
					end
				else
					return error(m, 2)
				end

				local s,m = pcall(setfenv, f, env);

				if not s then
					return error(m, 2);
				end

				return m;
			end);

			['print'] = (function(...)
				local args = { ... } do -- thanks tusky
					for i = 1, select ('#', ...) do
						args [i] = dad_b0x.internalFunctions.safe_tostring(args [i]);
					end;

					args = table.concat (args, '\t');

					dad_b0x.printString = dad_b0x.printString .. " " .. args .. "\n";
				end;
			end);
		};

		['Instances'] = {
			['debug'] = {
				['traceback'] = debug.traceback;
			};

			['os'] = {
				['time'] = os.time,
				['difftime'] = os.difftime,
				['date'] = os.date,
				['clock'] = os.clock,
			};

			['_G'] = {
				coroutine=coroutine,
				assert=assert,
				tostring=tostring,
				tonumber=tonumber,
				rawget=rawget,
				xpcall=dad_b0x.Fake.Functions['xpcall'],
				ipairs=ipairs,
				print=dad_b0x.Fake.Functions['print'],
				pcall=pcall,
				gcinfo=gcinfo,
				setfenv=setfenv,
				rawset=rawset,
				setmetatable=setmetatable,
				pairs=pairs,
				debug=dad_b0x.Fake.Instances['debug'],
				error=error,
				load=load,
				loadfile=dad_b0x.Blocked.Functions['loadfile'],
				rawequal=rawequal,
				string=string,
				unpack=unpack,
				table=table,
				require=dad_b0x.Blocked.Functions['require'],
				_VERSION=_VERSION,
				newproxy=newproxy,
				dofile=dad_b0x.Blocked.Functions['dofile'],
				collectgarbage=dad_b0x.Blocked.Functions['collectgarbage'],
				loadstring=loadstring,
				next=next,
				math=math,
				os=dad_b0x.Fake.Instances['os'],
				_G=dad_b0x.Fake.Instances['_G'],
				select=select,
				rawlen=rawlen,
				type=type,
				getmetatable=getmetatable,
				getfenv=dad_b0x.Fake.Functions['getfenv'],
			};
		};
	}
end

return (function(outputHandler, username)
	local s,m = pcall(function()
		-- Timeout the thread if taking too long
		local t = os.clock();
		debug.sethook(function()
	    if os.clock() - t > 10 and dad_b0x.printString == "" or os.clock() - t > 10 and dad_b0x.printString:len() > 2000 then
	      debug.sethook();
	      error('execution timed out', 0); -- terminate thread
	    end
		end, 'l');

		-- Set the rest of the environment
    setfenv(0, dad_b0x.Environments.level_1);
    setfenv(1, dad_b0x.Environments.level_1);

    local s,m = loadstring(outputHandler, 'dadb0t-execute');

    if not s then
			return {false, m};
    else
			jit.off(s);

      return setfenv(s, dad_b0x.Environments.level_1)();
    end
  end);

	-- Ultimately return what we need for this
  return {s, m, dad_b0x.printString}
end);
