local sub, match, format = string.sub, string.match, string.format
local remove = table.remove
local errFormat = 'Error: %s\nYou can run \'%s --help\' if you need some help'

local function makeError(obj, message)
    print(format(errFormat, message, obj.name))
end

local function getCommand(obj, input)
    local command = obj.commands[input]
    if not command then
        local possible = ''
        for _, v in pairs(obj.commands) do
            if v.possible[input] then
                possible = '\nDid you mean \''..v.name..'\'?'
                break
            end
        end
        return makeError(obj, 'invalid command \''..input..'\''..possible)
    end
    return command
end

local function getOption(obj, input, short)
    local option
    if short then
        for _, v in pairs(obj.options) do
            if v.shorts[input] then
                option = v
                break
            end
        end
    else
        option = obj.options[input]
    end
    if not option then
        local possible = ''
        if not short then
            for _, v in pairs(obj.options) do
                if v.possible[input] then
                    possible = '\nDid you mean \'--'..v.name..'\'?'
                    break
                end
            end
        end
        return makeError(obj, 'invalid option \''..(short and '-'..input or '--'..input)..'\''..possible)
    end
    return option
end

local function parseShorts(obj, input, options, args, i)
    if input == '' then
        return true
    end
    local short, value = match(input,'(.)(.*)')
    if short == 'h' then
        return obj:getHelp()
    end
    local option = getOption(obj, short, true)
    if not option then return end
    local optionArg = option.argument
    if not optionArg then
        options[option.name] = true
        return parseShorts(obj, sub(input, 2), options, args, i)
    end
    if value == '' then
        value = args[i + 1]
        args[i + 1] = nil
    end
    if not value and not optionArg.default then
        return makeError(obj, 'option \'-'..short..'\' requires an argument')
    end
    if value and optionArg.type == 'number' then
        local number = match(value, '%d+')
        if not number then
            return makeError(obj, 'option \'-'..short..'\' expects a number')
        end
        options[option.name] = number
    else
        options[option.name] = value or optionArg.default
    end
    return true
end

local function parseArgs(obj, args)
    local arguments, options, collection = {}, {}, {}
    local handleOpts, collect = true, false
    local index = 1
    for i = 1, #args do
        local arg = args[i]
        if not arg then goto continue end
        if arg == '--' then
            handleOpts = false
            goto continue
        end
        if handleOpts and sub(arg, 1, 2) == '--' then
            local input = sub(arg, 3)
            local name, value = match(input, '(.+)=(.+)')
            input = name or input
            if input == 'help' then
                return value and makeError(obj, 'option \'--help\' does not take an argument') or obj:getHelp()
            end
            local option = getOption(obj, input)
            if not option then return end
            local optionArg = option.argument
            if value and not optionArg then
                return makeError(obj, 'option \'--'..input..'\' does not take an argument')
            end
            if optionArg then
                if not value and not optionArg.default then
                    return makeError(obj, 'option \'--'..input..'\' requires an argument')
                end
                if value and optionArg.type == 'number' then
                    local number = match(value, '%d+')
                    if not number then
                        return makeError(obj, 'option \'--'..input..'\' expects a number')
                    end
                    options[input] = number
                else
                    options[input] = value or optionArg.default
                end
            end
            goto continue
        end
        if handleOpts and sub(arg, 1, 1) == '-' then
            if not parseShorts(obj, sub(arg, 2), options, args, i) then return end
            goto continue
        end
        if not obj.arguments[1] then
            return makeError(obj, obj.name..' does not take any arguments')
        end
        if collect then
            collection[#collection + 1] = arg
            goto continue
        end
        local argument = obj.arguments[index]
        if not argument then
            return makeError(obj, 'too many arguments')
        end
        if argument.many then
            collect = true
            collection[#collection + 1] = arg
            goto continue
        end
        if argument.type == 'number' then
            local number = match(arg, '%d+')
            if not number then
                return makeError(obj, 'arguemnt \''..argument.name..'\' expects a number')
            end
            arguments[argument.name] = number
        else
            arguments[argument.name] = arg
        end
        index = index + 1
        ::continue::
    end
    if collect then
        if index - #obj.arguments == 0  then
            local argument = obj.arguments[index]
            if argument.type == 'number' then
                for i = 1, #collection do
                    local number = match(collection[i], '%d+')
                    if not number then
                        return makeError(obj, 'argument \''..argument.name..'\' expects a list of numbers')
                    end
                    collection[i] = number
                end
            end
            arguments[argument.name] = collection
        end
    else
        for i = index + 1, #obj.arguments do
            if #collection == 1 then break end
            local argument = obj.arguments[i]
            local input = collection[#collection]
            if argument.type == 'number' then
                local number = match(input, '%d+')
                if not number then
                    return makeError(obj, 'argument \''..argument.name..'\' expects a number')
                end
                arguments[argument.name] = number
            else
                arguments[argument.name] = input
            end
            collection[#collection] = nil
        end
        local argument = obj.arguments[index]
        if argument.type == 'number' then
            for i = 1, #collection do
                local number = match(collection[i], '%d+')
                if not number then
                    return makeError(obj, 'argument \''..argument.name..'\' expects a list of numbers')
                end
                collection[i] = number
            end
        end
        arguments[argument.name] = collection
    end
    for i = 1, #obj.arguments do
        local argument = obj.arguments[i]
        if not arguments[argument.name] then
            if argument.default then
                arguments[argument.name] = argument.default
            else
                return makeError(obj, 'argument \''..argument.name..'\' is required')
            end
        end
    end
    return arguments, options
end

local function parseCommands(obj, args)
    if #args == 0 then
        return makeError(obj, 'no command given')
    end
    local input = args[i]
    if sub(input, 1, 2) == '--' then
        input = sub(input, 3)
        local name, value = match(input, '(.+)=(.+)')
        input = name or input
        if input == 'help' then
            if value then
                local command = getCommand(obj, value)
                if command then
                    command:getHelp()
                end
            else
                obj:getHelp()
            end
        else
            makeError(obj, 'invalid option \'--'..input..'\'')
        end
        return
    end
    if sub(input, 1, 1) == '-' then
        local short, value = match(sub(input, 2), '(.)(.*)')
        value = value == '' and args[2]
        if short == 'h' then
            if value then
                local command = getCommand(obj, input)
                if command then
                    command:getHelp()
                end
            else
                obj:getHelp()
            end
        else
            makeError(obj, 'invalid option \'-'..short..'\'')
        end
        return
    end
    local command = getCommand(obj, input)
    if command then
        remve(args, 1)
        command:parse(args)
    end
end

return {
    args = parseArgs,
    commands = parseCommands
}