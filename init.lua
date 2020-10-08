
local package, insert, getfenv, require, setmetatable, assert, setfenv, unpack, loadstring, create, resume = package, table.insert, getfenv, require, setmetatable, assert, setfenv, unpack, loadstring, coroutine.create, coroutine.resume;
local supported_files = {'lua'};
local preload, loaded, split, getSplitter = package.preload, package.loaded, function(s, spl)
    local result = {};
    for str in (s..spl):gmatch('(.-)'..spl) do
        insert(result, str);
    end;
    return result;
end, function(s)
    return ((s:find('/') ~= nil) and '/') or ((s:find('\\') ~= nil) and '\\') or '/';
end;
local getName, getExtension = function(path)
	return path:match('^.+'..getSplitter(path)..'(.+)$');
end, function(path)
	return path:match'^.+(%..+)$';
end;

local c_env, c_require, c_loadstring = getfenv(), require, loadstring;
local bundle = require'luvi'.bundle;
local local_path = args[0];
local name, extension = getName(local_path), getExtension(local_path);
local compiler = ((name == 'luvit.exe') and 0) or ((name == 'luvi.exe') and 1) or ((extension == '.exe') and 2) or 3;
local read = ((compiler == 0) and require'fs'.readFileSync) or ((compiler >= 1) and bundle.readfile);
local stat = ((compiler == 0) and require'fs'.statSync) or ((compiler >= 1) and bundle.stat);

local new_env = function()
    local env = {};
    for i, v in next, _G do
        if (type(v) == 'function') then
            local success, result = pcall(setfenv, v, env);
            if (success == true) then
                v = result;
            end;
        end;
        env[i] = v;
    end;
    return env;
end;

--environments created via loadstring do not have metatables but ones created from a compiler do
--the loadstring environments created are exactly the same in the same environment

local internal_generator_source = [=[
    local generator, loadstring, direct, splitter, read, stat, extend_env, c_require, loaded, preload = ...;
    local customRequire = function(libName)
        if (loaded[libName] ~= nil) then
            return loaded[libName];
        elseif (preload[libName] ~= nil) then
            return preload[libName]();
        end;
        local c_env = getfenv();
        local limport_data = c_env.limport_data;
        local directors = {limport_data.cd; direct..splitter..'libs'; direct;};
        for i = 1, #directors do
            local pathFile = directors[i]..splitter..libName;
            local pathExtension = pathFile..'.lua';
            local stats = stat(pathExtension);
            if (stats ~= nil) then
                local body = assert(read(pathExtension));
                local convert = assert(loadstring(body));
                local ls_env = getfenv(convert);
                local ex_ls_env = extend_env(ls_env, limport_data.global_env, c_env);
                ex_ls_env.limport_data = {
                    ls_env = ls_env;
                    global_env = limport_data.global_env;
                    parent_env = c_env;
                    cd = pathFile;
                };
                local new_require = generator(direct, splitter, read, stat, extend_env, c_require, loaded, preload);
                ex_ls_env.require = setfenv(new_require, ex_ls_env);
                local result = {setfenv(convert, ex_ls_env)()};
                loaded[libName] = unpack(result);
                return unpack(result);
            end;
        end;
        return c_require(libName);
    end;
    return customRequire;]=];

local loadstring = function(...)
    return setfenv(c_loadstring(...), new_env());
end;

local extend_env = function(loadstring_env, global_env, parent_env)
    local index = function(self, index)
        local global_result = global_env[index];
        if (global_result == nil) then
            return parent_env[index];
        end;
        return global_result;
    end;
    local meta = {__index = index; __newindex = function(self, index, value)
        global_env[index] = value;
    end};
    return setmetatable(loadstring_env, meta);
end;

local generator; generator = function(direct, splitter, read, stat, extend_env, c_require, loaded, preload)
    return loadstring(internal_generator_source)(generator, loadstring, direct, splitter, read, stat, extend_env, c_require, loaded, preload);
end;

local singleImport = function(libraryName)
    --We want to be able to import entire libraries and single files
    local splitter = getSplitter(libraryName);
    local all = split(libraryName, splitter);
    local isMulti = #all > 1;
    if (isMulti == true) then --stuff like 
        --'ekidona/libs/class' needs to inherit the environment of 'ekidona' in one way or another
        --'ekidona/libs/class.lua' needs to be compatiable
        --'ekidona/package' and 'ekidona/package.lua' also needs to be compatiable with inheriting 'ekidona's environment
        --import names should only accept true pathing
        --because import affects the main thread that required the module we need to adjust preload still
        local direct = all[#all];
        local hasExtension = direct:find('%.') ~= nil;
        if (hasExtension == true) then
            --Library Names must direct to the actual directory, no fake directories or short hand notations
            local stats = stat(libraryName);
            if (stats ~= nil and stats.type == 'file') then
                --I decided to just say fuck inheriting environments of their respective libraries if you want the library just require it
                local extension = getExtension(direct);
                local paths = {libraryName, libraryName:gsub(extension, ''), direct, direct:gsub(extension, '')};
                local loader = function(...)
                    local body = assert(read(libraryName));
                    local convert = assert(loadstring(body));
                    local result = {setfenv(convert, c_env)(...)};
                    for i = 1, #paths do
                        loaded[paths[i]] = unpack(result);
                    end;
                    return unpack(result);
                end;
                for i = 1, #paths do
                    preload[paths[i]] = loader;
                end;
                --preload[libraryName], preload[libraryName:gsub(extension, '')], preload[direct], preload[direct:gsub(extension, '')] = loader, loader, loader, loader;
            end;
        elseif (hasExtension == false) then
            --Probably a standard directory search to a file maybe or another folder
            --ekidona/libs/package, deps/ekidona, deps/ekidona/libs/class, deps/ekidona/libs/package
            --package, ekidona, class, package
            local stats = stat(libraryName);
            if (stats ~= nil and stats.type == 'directory') then
                local full_direct = libraryName..splitter..'init.lua';
                local stats_i = stat(full_direct);
                local paths = {libraryName, direct};
                if (stats_i ~= nil and stats_i.type == 'file') then
                    local customRequire = generator(libraryName, splitter, read, stat, extend_env, c_require, loaded, preload);
                    local loader = function(...)
                        local init_body = assert(read(full_direct));
                        local convert = assert(loadstring(init_body));
                        local ls_env = getfenv(convert);
                        local global_env = new_env();
                        local ex_ls_env = extend_env(ls_env, global_env, c_env);
                        ex_ls_env.limport_data = {
                            ls_env = ls_env;
                            global_env = global_env;
                            parent_env = c_env;
                            cd = libraryName;
                        };
                        ex_ls_env.require = setfenv(customRequire, ex_ls_env);
                        local result = {setfenv(convert, ex_ls_env)(...)};
                        for i = 1, #paths do
                            loaded[paths[i]] = unpack(result);
                        end;
                        return unpack(result);
                    end;
                    for i = 1, #paths do
                        preload[paths[i]] = loader;
                    end;
                else --Init does not exist
                    local loader = function(...)
                        for i = 1, #paths do
                            loaded[paths[i]] = true;
                        end;
                        return true;
                    end;
                    for i = 1, #paths do
                        preload[paths[i]] = loader;
                    end;
                end;
            else --Probably a file
                for i = 1, #supported_files do
                    local ext = supported_files[i];
                    local full_direct = libraryName..'.'..ext;
                    local stats_s = stat(full_direct);
                    --assert(success_s and stat_type_s == 'directory', 'Impossible path for second check');
                    if (stats_s ~= nil and stats_s.type == 'file') then
                        local paths = {libraryName, full_direct, direct, direct..'.'..ext};
                        local loader = function(...)
                            local body = assert(read(full_direct));
                            local convert = assert(loadstring(body));
                            local result = {setfenv(convert, c_env)(...)};
                            for e = 1, #paths do
                                loaded[paths[e]] = unpack(result);
                            end;
                            return unpack(result);
                        end;
                        for e = 1, #paths do
                            preload[paths[e]] = loader;
                        end;
                        break;
                    end;
                end;
            end;
        end;
    elseif (isMulti == false) then --stuff like 'ekidona'
        local direct = all[1];
        local hasExtension = direct:find('%.') ~= nil;
        if (hasExtension == true) then
            --'ekidona.lua', must be a file
            local extension = getExtension(direct);
            local no_extension = direct:gsub(extension, '');
            local paths = {direct, no_extension};
			local loader = function(...)
                local body = assert(read(direct));
                local convert = assert(loadstring(body));
                local result = {setfenv(convert, c_env)(...)};
                for i = 1, #paths do
                    loaded[paths[i]] = unpack(result);
                end;
                return unpack(result);
            end;
            for i = 1, #paths do
                preload[paths[i]] = loader;
            end;
        elseif (hasExtension == false) then
            --'ekidona', could be a directory or a file
            local stats = stat(direct);
            --stat requires file extension for file types
			--assert(success and stat_type == 'file', 'Impossible path');
            if (stats ~= nil and stats.type == 'directory') then
                local full_direct = direct..splitter..'init.lua';
                local stats_i = stat(full_direct);
                if (stats_i ~= nil and stats_i.type == 'file') then --Init exists
                    local customRequire = generator(direct, splitter, read, stat, extend_env, c_require, loaded, preload);
                    preload[direct] = function(...)
                        local init_body = assert(read(full_direct));
                        local convert = assert(loadstring(init_body));
                        local ls_env = getfenv(convert);
                        local global_env = new_env();
                        local ex_ls_env = extend_env(ls_env, global_env, c_env);
                        ex_ls_env.limport_data = {
                            ls_env = ls_env;
                            global_env = global_env;
                            parent_env = c_env;
                            cd = direct;
                        };
                        ex_ls_env.require = setfenv(customRequire, ex_ls_env);
                        return setfenv(convert, ex_ls_env)(...);
                    end;
                else --Init does not exist
                    preload[direct] = function(...)
                        return true;
                    end;
                end;
            else --We have to check for supported file extensions, must check if is a file
                for i = 1, #supported_files do
                    local ext = supported_files[i];
                    local full_direct = direct..'.'..ext;
                    local stats_s = stat(full_direct);
                    --assert(success_s and stat_type_s == 'directory', 'Impossible path for second check');
                    if (stats_s ~= nil and stats_s.type == 'file') then
                        local paths = {direct, full_direct};
                        local loader = function(...)
                            local body = assert(read(full_direct));
                            local convert = assert(loadstring(body));
                            local result = {setfenv(convert, c_env)(...)};
                            for e = 1, #paths do
                                loaded[paths[e]] = unpack(result);
                            end;
                            return unpack(result);
                        end;
                        for e = 1, #paths do
                            preload[paths[e]] = loader;
                        end;
                        break;
                    end;
                end;
            end;
        end;
    end;
end;

return function(...)
    local list = {...};
    for i = 1, #list do
        local thread = create(singleImport);
        assert(resume(thread, list[i]));
    end;
end;