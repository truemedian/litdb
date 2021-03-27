
local setfenv, unpack, pcall, assert, loadfile = setfenv, unpack, pcall, assert, loadfile;
local package, os, string = package, os, string;
local loaded, preload, path, getenv, gmatch = package.loaded, package.preload, package.path, os.getenv, string.gmatch;
local env = getfenv();
local tab = string.char(9);
local require = function(dir)
	if (loaded[dir] ~= nil) then
		return loaded[dir];
	end;
	local paths = LUA_PATH or getenv('LUA_PATH') or path;
    local loader = preload[dir];
    if (loader ~= nil) then
        local closure = {setfenv(loader, env)(dir)}
        loaded[dir] = unpack(closure);
        return unpack(closure);
    end;
    local check_traceback = tab.."no field package.preload['"..dir.."']";
	for path in gmatch(paths, '[^;]+') do
        local true_path = path:gsub('?', dir);
        local ran, result = pcall(function() 
            return assert(loadfile(true_path));
        end);
        if (ran == true) then
            local closure = {setfenv(result, env)(dir)}
            loaded[dir] = unpack(closure);
            return unpack(closure);
        end;
        check_traceback = check_traceback..'\n'..tab.."no file '"..true_path.."'";
	end;
    error("module '"..dir.."' not found:\n"..check_traceback);
end;
env.require = require;
return require;