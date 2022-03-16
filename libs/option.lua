local sub = string.sub

local option = {}
option.__index = option

local function makeOption(name)
    local possible = {}
    for i = 1, #name do
        possible[sub(name, 1, i - 1)..sub(name, i + 1)] = true
    end
    return {name = name, description = 'No description provided.', shorts = {}, possible = possible}
end

function option:setDescription(description)
    self.description = description
    return self
end

function option:setArgument(argument)
    assert(not argument.many, 'Option arguments cannot take many values')
    self.argument = argument
    return self
end

function option:addShort(short)
    assert(#short == 1, 'Short option must be one character long.')
    self.shorts[short] = true
    return self
end

function option:init(name)
    return setmetatable(makeOption(name), self)
end

return option