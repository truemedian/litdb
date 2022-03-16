local argument = {}
argument.__index = argument

local function makeArgument(name)
    return {
        name = name,
        description = 'No description provided.',
        type = 'string',
        many = false,
    }
end

local validTypes = {string = true, number = true}

function argument:setDescription(description)
    self.description = description
    return self
end

function argument:setDefault(value)
    self.default = value
    return self
end

function argument:setType(typ)
    assert(validTypes[typ], 'Invalid type \''..tostring(typ)..'\'')
    self.type = typ
    return self
end

function argument:setMany()
    self.many = true
    return self
end

function argument:init(name)
    return setmetatable(makeArgument(name), self)
end

return argument