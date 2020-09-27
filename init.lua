
local package, insert, getfenv, require, getmetatable, setmetatable, rawget, assert, setfenv, unpack, loadstring, create, resume = package, table.insert, getfenv, require, getmetatable, setmetatable, rawget, assert, setfenv, unpack, loadstring, coroutine.create, coroutine.resume;
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

local c_env, c_require = getfenv(), require;
local bundle = require'luvi'.bundle;
local local_path = args[0];
local name, extension = getName(local_path), getExtension(local_path);
local compiler = ((name == 'luvit.exe') and 0) or ((name == 'luvi.exe') and 1) or ((extension == '.exe') and 2) or 3;
local read = ((compiler == 0) and require'fs'.readFileSync) or ((compiler >= 1) and bundle.readfile);
local stat = ((compiler == 0) and require'fs'.statSync) or ((compiler >= 1) and bundle.stat);

--environments created via loadstring do not have metatables but ones created from a compiler do
local inherit_of = function(true_env, super_env)
    local meta = getmetatable(true_env);
    if (meta == nil) then
        local fake_env = {};
        return setmetatable(fake_env, {__index = function(self, index) 
            local original_result = rawget(fake_env, index);
            if (original_result == nil) then
                local secondary_result = true_env[index];
                if (secondary_result == nil) then
                    return super_env[index];
                end;
                return secondary_result;
            end;
            return original_result;
        end;});
    else
        meta.__index = function(self, index)
            local original_result = rawget(self, index);
            if (original_result == nil) then
                return super_env[index];
            end;
            return original_result;
        end;
        return true_env;
    end;
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
                    local custom_loaded = {};
                    local customRequire; customRequire = function(libName)
                        if (custom_loaded[libName] ~= nil) then return custom_loaded[libName] ~= nil; end;
                        local c_env = getfenv();
                        local directors = {c_env.cd; libraryName..splitter..'libs'; libraryName;};
                        for i = 1, #directors do
                            local pathFile = directors[i]..splitter..libName;
                            local pathExtension = pathFile..'.lua';
                            local stats = stat(pathExtension);
                            if (stats ~= nil) then
                                local body = assert(read(pathExtension));
                                local convert = assert(loadstring(body));
                                local true_f_env = getfenv(convert);
                                true_f_env.cd = pathFile;
                                true_f_env.require = setfenv(customRequire, true_f_env);
                                local result = {setfenv(convert, inherit_of(true_f_env, c_env))()};
                                custom_loaded[libName] = unpack(result);
                                return unpack(result);
                            end;
                        end;
                        return c_require(libName);
                    end;
                    local loader = function(...)
                        local init_body = assert(read(full_direct));
                        local convert = assert(loadstring(init_body));
                        local true_f_env = getfenv(convert);
                        true_f_env.require = setfenv(customRequire, true_f_env);
                        true_f_env.cd = libraryName;
                        local result = {setfenv(convert, inherit_of(true_f_env, c_env))(...)};
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
                    local custom_loaded = {};
                    local customRequire; customRequire = function(libName)
                        --this function is more complicated than this
                        --require'class', 'package', 'init', 'class/test'
                        --we will search through the main directory and libs but also we need to search for a true env
                        --we don't use full_direct because it's a path to the initializer
                        if (custom_loaded[libName] ~= nil) then return custom_loaded[libName]; end;
                        local c_env = getfenv();
                        local directors = {c_env.cd; direct..splitter..'libs'; direct;};
                        for i = 1, #directors do
                            local pathFile = directors[i]..splitter..libName;
                            local pathExtension = pathFile..'.lua';
                            local stats = stat(pathExtension);
                            if (stats ~= nil) then
                                local body = assert(read(pathExtension));
                                local convert = assert(loadstring(body));
                                local true_f_env = getfenv(convert);
                                true_f_env.cd = pathFile;
                                true_f_env.require = setfenv(customRequire, true_f_env);
                                local result = {setfenv(convert, inherit_of(true_f_env, c_env))()};
                                custom_loaded[libName] = unpack(result);
                                return unpack(result);
                            end;
                        end;
                        return c_require(libName);
                    end;
                    preload[direct] = function(...)
                        local init_body = assert(read(full_direct));
                        local convert = assert(loadstring(init_body));
                        local true_f_env = getfenv(convert);
                        true_f_env.require = setfenv(customRequire, true_f_env);
                        true_f_env.cd = direct;
                        --[[ Designed to test if the env has a metatable already
                        local meta = {};
                        meta.__index = function(self, index) return rawget(true_f_env); end;
                        setmetatable(true_f_env, meta);]]
                        return setfenv(convert, inherit_of(true_f_env, c_env))(...);
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