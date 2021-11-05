local allowed = {'string', 'function'}

local format = string.format
local find = table.find

local function checkChannel(self, channel)
    local client, error = self.client, nil
    if client and client.isInit and type(channel) == 'string' then
        local sucess, error = client.get:getChannel(channel)

        if not sucess then return nil, error end
    else
        --error = 'Cannot confirm channel existance.'
    end

    return not error and true, error
end

local function newChannel(self, channel)
    local errors = self._default_errors
    local normal, warn = errors.normal, errors.warning

    local type1, type2 = type(self), type(channel)
    if type1 ~= 'table' then
        return nil, format(normal, 1, 'newChannel', 'table', type1)
    elseif find(self._types.channels, channel or ':fn') then
        return nil, 'Cannot overwrite channels'
    end

    local channels = {}

    if type2 == 'table' then
        for name, channel in pairs(channel) do
            local type = find(allowed, type(channel))
            local check = checkChannel(self, channel)
            channels[#channels+1] = check and type and channel or nil
        end
    elseif type2 == 'string' or type2 == 'function' then
        local check = checkChannel(self, channel)
        channels[#channels+1] = check and channel or nil
    else
        return nil, format(warn, 'value', 'channel', type2, 'newChannel')
    end

    local chs = self._types.channels or {}
    for i,v in pairs(channels) do chs[i] = v end; self._types.channels = chs

    if not self._default_channel then
        self._default_channel = type2 == 'string' and channel
    end

    return self
end

local function getChannelInt(self, channel)
    local errors = self._default_errors
    local normal = errors.normal

    local type1, type2 = type(self), type(channel)
    if type1 ~= 'table' then
        return nil, format(normal, 1, 'getChannelInt', 'table', type1)
    elseif type2 ~= 'channel' then
        return nil, format(normal, 2, 'getChannelInt', 'string', type2)
    end

    local chs = self._types.channels
    return find(chs, channel)
end

local function getChannel(self, int)
    local errors = self._default_errors
    local normal = errors.normal

    local type1, type2 = type(self), type(int)
    if type1 ~= 'table' then
        return nil, format(normal, 1, 'getChannel', 'table', type1)
    elseif type2 ~= 'number' and not type2 == 'string' then
        return nil, format(normal, 2, 'getChannel', 'number', type2)
    end

    local chs = self._types.channels; local cint = type(int) == 'string' and getChannelInt(self, int)
    local channel = chs[cint or int]
    return type(channel) == 'function' and channel(self) or channel
end

local function remChannel(self, int)
    local errors = self._default_errors
    local normal = errors.normal

    local type1, type2 = type(self), type(int)
    if type1 ~= 'table' then
        return nil, format(normal, 1, 'remChannel', 'table', type1)
    end

    local channels = self._types.channels
    if type2 == 'table' then
        for _, int in pairs(int) do
            channels[int] = nil
        end
    elseif type2 == 'string' then
        channels[getChannelInt(self, int) or #channels+1] = nil
    elseif type2 == 'number' then
        channels[int] = nil
    end

    return self
end

return setmetatable({
    checkChannel = checkChannel,
    newChannel = newChannel,
    getChannelInt = getChannelInt,
    getChannel = getChannel,
    remChannel = remChannel,
}, {
    __call = function(self, table)
        for index, value in pairs(self) do
            table[index] = value
        end

        return table
    end,
})