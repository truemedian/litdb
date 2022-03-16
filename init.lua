local luvit, luvi
local success, package = pcall(require, 'bundle:/package.lua')
if success and type(package) == 'table' then
    if package == 'luvit/luvit' then
        luvit = true
    else
        luvi = true
    end
end

return {
    command = require(luvit and 'command' or 'command'),
    argument = require(luvit and 'argument' or 'argument'),
    program = require(luvit and 'program' or 'program'),
    option = require(luvit and 'option' or 'option')
}