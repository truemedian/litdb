local parser = require('parser')
local format = string.format
local remove, concat = table.remove, table.concat
local sort, sorter = table.sort, function(a, b) return b.default ~= nil end
local helpFormat = '%s\n\nUsage:\n\n    %s\n\n    Option arguments that do not have a defined default value are mandatory.'
local paramFormat = '\n\n    %s\n        %s'
local errFormat = 'Error: %s\nYou can run \'%s --help\' if you need some help'

local program = {}
program.__index = program

local function makeProgram(name)
    return {name = name, description = 'No description provided.', commands = {}, arguments = {}, options = {}, notes = {}}
end

local function convert(default)
    return type(default) == 'table' and concat(default, ' ') or tostring(default)
end

function program:handler()
    local input, luvi
    if args then
        luvi = true
        input = args
    else
        input = arg
    end
    if not input then
        print('Error: could not get command-line arguments')
        return
    end
    if luvi then
        local success, pkg = pcall(require, 'bundle:/package.lua')
        if success and type(pkg) == 'table' and pkg.name == 'luvit/luvit' then
            remove(input, 1)
        end
    end
    return self:parse(input)
end

function program:parse(args)
    if next(self.commands) then
        local command, arguments = parser.commands(self, args)
        if command then
            return command:parse(arguments)
        end
    end
    local arguments, options = parser.args(self, args)
    if arguments then
        local success, err = pcall(self.execute, self, arguments, options)
        if not success then
            print('Error: '..err..'\nContact the distributor of this application for more assistance')
        end
    end
end

function program:error(message)
    print(format(errFormat, message, self.name))
end

function program:setDescription(description)
    self.description = description
    return self
end

function program:addNote(note)
    self.notes[#self.notes + 1] = note
    return self
end

function program:addCommand(command)
    assert(self.execute == nil, 'A program with an execute function cannot have any subcommands')
    command.parent = self
    self.commands[command.name] = command
    return self
end

function program:addArgument(argument)
    local arguments = self.arguments
    for i = 1, #arguments do
        local arg = arguments[i]
        assert(arg.name ~= argument.name, 'Duplicate arguments')
        if argument.many then
            assert(not arg.many, 'Can not have more than one argument that take many values')
        end
    end
    arguments[#arguments + 1] = argument
    sort(arguments, sorter)
    return self
end

function program:addOption(option)
    option.parent = self
    self.options[option.name] = option
    return self
end

function program:setExecute(fn)
    assert(next(self.commands) == nil, 'A program with subcommands cannot have an execute function')
    self.execute = fn
    return self
end

function program:getHelp()
    if next(self.commands) then
        local help = self.description..'\n\nUsage:'
        for _, command in pairs(self.commands) do
            help = help..format(paramFormat, command:getUsage(), command.description)
        end
        help = '\n\nOptions:'..format(paramFormat, '-h, --help=command', 'If a command is provided then display help for that command otherwise display this help message and exit')
        if next(self.notes) then
            help = help..'\n\nNotes:'
            for i = 1, #self.notes do
                help = help..'\n\n    '..self.notes[i]
            end
        end
        return print(help)
    end
    local help = format(helpFormat, self.description, self:getUsage())..'\n\nOptions:'
    for _, option in pairs(self.options) do
        local name = ''
        local description = option.description
        local optionArg = option.argument
        for short in pairs(option.shorts) do
            name = name..'-'..short..', '
        end
        name = name..'--'..option.name
        if optionArg then
            name = name..'='..optionArg.name.. ' <'..optionArg.type..'>'
            description = optionArg.default and description..' (default: '..convert(optionArg.default)..')' or description
        end
        help = help..format(paramFormat, name, description)
    end
    help = help..format(paramFormat, '-h, --help', 'Display this help message and exit')
    if next(self.arguments) then
        help = help..'\n\nArguments:'
        for i = 1, #self.arguments do
            local argument = self.arguments[i]
            help = help..format(paramFormat, argument.name..(argument.many and '... <'..argument.type..'>' or ' <'..argument.type..'>'), argument.default and argument.description..' (default: '..convert(argument.default)..')' or argument.description)
        end
    end
    if next(self.notes) then
        help = help..'\n\nNotes:'
        for i = 1, #self.notes do
            help = help..'\n\n    '..self.notes[i]
        end
    end
    return print(help)
end

function program:getUsage()
    local argString = ''
    for i = 1, #self.arguments do
        local argument = self.arguments[i]
        argString = argString..argument.name..(argument.many and '... ' or ' ')
    end
    return self.name..' [options...] '..argString
end

function program:init(name)
    return setmetatable(makeProgram(name), self)
end
return program