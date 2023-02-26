local name = '_tests/init.lua'
local errorColoured = '\27[1;31mERROR IN\27[0m:'

local success, extensions = pcall(require, './../init.lua')
if not success then
    print('[', errorColoured, name, ']', '`lua-extension` was not found or errored:', extensions)
    return
end

success, extensions = pcall(extensions)
if not success then
    print('[', errorColoured, name, ']', '`lua-extension` encounter an error while initing:', extensions)
    return
end

local fs = require 'fs'
if not fs then
    print('[', errorColoured, name, ']', '`fs` was NOT found')
    return
elseif fs.readdir == nil then
    print('[', errorColoured, name, ']', '`fs` was found but has not "readdir" function')
    return
end

local re, running, yield = coroutine.resume, coroutine.running, coroutine.yield

local tests = { }

local thread = running()
fs.readdir('_tests', function(_, files)
    if not files then
        return error()
    end

    for _, file in ipairs(files) do
        if not file:find '^init.lua' then
            tests[file] = require('./'..file)
        end
    end

    local success, value = re(thread)
    if not success then
        error(value)
    end
end)

do yield() end


for name, module in pairs(tests) do
    local data = { pcall(module) }
    local success = data[1]
    if not success then
        print('[', errorColoured, name, '] →', data[2])
    end

    table.remove(data, 1)

end