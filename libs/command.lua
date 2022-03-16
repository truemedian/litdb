local parseArgs = require('parser').args
local format = string.format
local sort, sorter = table.sort, function(a, b) return b.default ~= nil end
local helpFormat = '%s\n\nUsage:\n\n    %s\n\n    Option arguments that do not have a defined default value are mandatory.'
local paramFormat = '\n\n    %s\n        %s'

local command = {}
command.__index = command

local function makeCommand(name)
    local possible = {}
    for i = 1, #name do
        possible[sub(name, 1, i - 1)..sub(name, i + 1)] = true
    end
    return {name = name, description = 'No description provided.', options = {}, arguments = {}, notes = {}, possible = possible}
end

local function convert(default)
    return type(default) == 'table' and concat(default, ' ') or tostring(default)
end

function command:parse(args)
    local arguments, options = parseArgs(self, args)
    if arguments then
        local success, err = pcall(self.execute, arguments, options)
        if not success then
            print('Error: '..err..'\nContact the distributor of this application for more assistance')
        end
    end
end

function command:setDescription(description)
    self.description = description
    return self
end

function command:addNote(note)
    self.notes[#self.notes + 1] = note
    return self
end

function command:addOption(option)
    self.options[option.name] = option
    return self
end

function command:addArgument(argument)
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

function command:getHelp()
    local help = format(helpFormat, self.description, self:getUsage())..'\n\nOptions:'
    for _, option in pairs(self.options) do
        local name = ''
        local description = option.description
        local optionArg = option.argument
        for short in pairs(option.shorts) do
            name = name..'-'..short..', '
        end
        if optionArg then
            name = name..'='..optionArg.name..' <'..optionArg.type..'>'
            description = optionArg.default and description..' (default: '..convert(optionArg.default)..')' or description
        end
        help = help..format(paramFormat, name, description)
    end
    help = help..format(paramFormat, '-h, --help', 'Display this help message and exit')
    if next(self.arguments) then
        help = help..'\n\nArguments:'
        for i = 1, #self.arguments do
            local argument = self.arguments[i]
            help = help..format(paramFormat, argument.name..(argument.many and '... <'..argument.type..'>' or ' <'..argument.type..'>'), argument.description)
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

function command:getUsage()
    local argString = ''
    for i = 1, #self.arguments do
        local argument = self.arguments[i]
        argString = argString..argument.name..(argument.many and '... ' or ' ')
    end
    return self.name..' [options...] '..argString
end 

function command:setExecute(fn)
    self.execute = fn
    return self
end

function command:init(name)
    return setmetatable(makeCommand(name), self)
end

return command
