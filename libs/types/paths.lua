local format = string.format

local function setPath(self, name, path)
    local errors = self._default_errors
    local normal = errors.normal

    local type1, type2, type3 = type(self), type(name), type(path)
    if type1 ~= 'table' then
        return nil, format(normal, 1, 'setPath', 'table', type1)
    elseif type2 ~= 'string' then
        return nil, format(normal, 2, 'setPath', 'string', type2)
    elseif type3 ~= 'string' then
        return nil, format(normal, 3, 'setPath', 'string', type3)
    end

    self._types.paths[name] = path

    return self
end

local function getPath(self, name)
    local errors = self._default_errors
    local normal = errors.normal

    local type1, type2 = type(self), type(name)
    if type1 ~= 'table' then
        return nil, format(normal, 1, 'getPath', 'table', type1)
    elseif type2 ~= 'string' then
        return nil, format(normal, 2, 'getPath', 'string', type2)
    end

    local paths = self._types.paths or {}
    return not name and self._default_path or name and paths[name] or name and self._default_paths[name .. '_path'] 
end

local function remPath(self, name)
    local errors = self._default_errors
    local normal = errors.normal

    local type1, type2 = type(self), type(name)
    if type1 ~= 'table' then
        return nil, format(normal, 1, 'remPath', 'table', type1)
    elseif type2 ~= 'string' then
        return nil, format(normal, 2, 'remPath', 'string', type2)
    end

    local paths = self._types.paths
    paths[name] = nil

    return self
end

return setmetatable({
    setPath = setPath,
    getPath = getPath,
    remPath = remPath
}, {
    __call = function(self, table)
        for index, value in pairs(self) do
            table[index] = value
        end

        return table
    end
})