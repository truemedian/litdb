if not args then
    package.path = debug.getinfo(1).short_src:gsub('init.lua', 'libs\\?.lua;')..package.path
end
return {
    command = require('command'),
    argument = require('argument'),
    program = require('program'),
    option = require('option')
}