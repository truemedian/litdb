local json = require 'json'

local overwrite = require 'content'
local sf, set, rem = overwrite.searchFor, overwrite.apply, overwrite.remove

local insert, find, tset, getn = table.insert, table.find, table.set, table.getn
local format, dump, sfind = string.format, string.dump, string.find
local create, yield, status, close, resume = coroutine.create, coroutine.yield, coroutine.status, coroutine.close, coroutine.resume

local default_errors = {
    bad = 'Incorrect argument #%s for %s (%s expected got %s)',
    warning = 'Expected %s for %s are %s (in %s)', -- Expected value for channel are nil (in getSlot)
}

local bad, warn = default_errors.bad, default_errors.warning

local function encode(table, _in)
    local type1 = type(table)
    if type1 ~= 'table' then
        if type1 == 'function' then
            local fn = table

            return dump(fn, true)
        end

        return nil, format(bad, 1, 'encode', 'table', type1)
    end

    local response = _in and table or {}
    for key, value in pairs(table) do
        local typev = type(value)
        if typev == 'function' then
            local string = dump(value, true)

            response[key] = string
        elseif typev == 'table' and find(value, ':function') then
            local ret = encode(value)
            if ret then
                tset(response, key)
                for i, v in pairs(ret) do
                    response[key][i] = v
                end
            end
        else
            response[key] = value
        end
    end

    return response
end

local function decode(table, env, _in)
    local type1 = type(table)
    if type1 ~= 'table' then
        if type1 == 'string' then
            local parse = json.decode(table)
            if type(parse) == 'table' then
                return decode(parse, env, _in)
            elseif type(parse) == 'string' then
                return load(parse, nil, nil, env)
            end
        end

        return nil, format(bad, 1, 'decode', 'table', type1)
    end

    local response, errors = _in and table or {}, {}

    local nerror = 1
    for key, value in pairs(table) do
        local typev = type(value)
        if typev == 'string' then
            local fn, error = load(value, nil, 'b', env)
            if not fn and error then
                if not error:find('wrong mode') then
                    errors[tostring(key) .. '#' .. nerror] = error
                    nerror = nerror + 1
                else
                    response[key] = value
                end
            else
                response[key] = fn
            end
        elseif typev == 'table' and find(value, '%string') then
            local ret, errors = decode(value, env)
            
            if ret then
                tset(response, key) 

                for i, v in pairs(ret) do
                    response[key][i] = v
                end
            else
                errors[tostring(key) .. '#' .. nerror] = errors
            end
        else
            response[key] = value
        end
    end

    return response, getn(errors) ~= 0 and errors or nil
end

local function getClientChannel(self, client, id)
    local type3 = type(id)
    if not self or not client or type3 ~= 'string' then
        return nil, 'Check args'
    end

    rawset(self, '_running_thread', create(function()
        local channel = client.get:getChannel(id)
        yield(channel) -- wait for channel
    end))

    insert(self._threads, self._running_thread)

    return self._running_thread, #self._threads
end

-- WARNING FORMATS
local noclient = format(warn, 'value', 'client', '%q', '%q')
local nochannel = format(warn, 'value', 'channel', '%q', '%q')

local function setSlot(self, id, value)
    if self:getRunningThread() then
        return nil, 'Another thread already running'
    end

    local type1, type2 = type(self), type(id)
    if type1 ~= 'table' then
        return error(format(bad, 'self', 'setSlot', 'table', type1))
    elseif type2 ~= 'string' then
        return error(format(bad, 1, 'setSlot', 'string', type2))
    elseif not value then
        return error(format(bad, 2, 'setSlot', 'any', nil))
    end

    local client, name = self.client, tostring(self._name)
    if not client then
        return nil, format(noclient, nil, name)
    end

    local thread, _ = getClientChannel(self, client, self._channel_id)

    -- for slotin in channel do
    --     channel = slotin
    -- end
    local _, channel = resume(thread)

    if channel then
        local messageId, _ = sf(name .. '.json', id)

        local value = encode(value) or value

        if not messageId then
            do                
                self:quitSlot(id)
            end

            local message, error = channel:send(json.encode(value))

            if message then
                local sucess, error = set(name .. '.json', id, message.id, 'module')

                return sucess , error
            end

            return nil, error
        else
            local message, _ = channel:getMessage(messageId)

            if message then
                local sucess, _ = message:setContent(json.encode(value))
                if sucess then
                    return true 
                else
                    return nil, _
                end
            else
                return self:setSlot(id, value)
            end
        end
    end

    return nil, format(nochannel, type(channel), name)
end

local geterr = 'Not founded data store in %s [, with id %s]'

local function getSlot(self, id, data)
    if self:getRunningThread() then
        return nil, 'Another thread already running'
    end

    local type1, type2 = type(self), type(id)
    if type1 ~= 'table' then
        return error(format(bad, 'self', 'getSlot', 'table', type1))
    elseif type2 ~= 'string' then
        return error(format(bad, 1, 'getSlot', 'string', type2))
    end

    local env, raw
    if type(data) == 'table' then
        env = rawget(data, '_env'); raw = rawget(data, 'jsonkraw')
    end

    local client, name = self.client, tostring(self._name)
    if not client then
        return nil, format(noclient, nil, name)
    end

    local post, _ = getClientChannel(self, client, self._channel_id)

    -- for slotin in channel do
    --     channel = slotin
    -- end
    local _, channel = resume(post)

    if channel then
        local messageId, _ = sf(name .. '.json', id)

        if messageId then
            local message, error = channel:getMessage(messageId)

            if message then
                local cont = message.content

                local dec = decode(cont, env)

                return not raw and dec or cont
            end

            return nil, error
        end

        return nil, format(geterr, name, id)
    end

    return nil, format(nochannel, type(channel), name)
end

local function quitSlot(self, id)
    if self:getRunningThread() then
        return nil, 'Another thread already running'
    end

    local type1, type2 = type(self), type(id)
    if type1 ~= 'table' then
        return error(format(bad, 'self', 'quitSlot', 'table', type1))
    elseif type2 ~= 'string' then
        return error(format(bad, 1, 'quitSlot', 'string', type2))
    end

    local client, name = self.client, tostring(self._name)
    if not client then
        return nil, format(noclient, nil, name)
    end

    local unpost, _ = getClientChannel(self, client, self._channel_id)

    -- for slotin in channel do
    --     channel = slotin
    -- end

    local _, channel = resume(unpost)

    if channel then
        local messageId, _ = sf(name .. '.json', id)

        if messageId then
            local sucess, error = channel:getMessage(messageId):delete()

            if sucess then
                local srem, err = rem(name .. '.json', id)
                if srem then
                    return true
                else
                    return nil, err
                end
            end

            return nil, error
        end

        return nil, format(geterr, name, id)
    end

    return nil, format(nochannel, type(channel), name)
end

local function escape(self, id)
    return self:quitSlot(id)
end

local function quitAllSlots(self)
    if self:getRunningThread() then
        return nil, 'Another thread already running'
    end

    local type1 = type(self)
    if type1 ~= 'table' then
        return error(format(bad, 'self', 'quitAllSlots', 'table', type1))
    end

    local client, name = self.client, tostring(self._name)
    if not client then
        return nil, format(noclient, nil, name)
    end

    local module = sf(name .. '.json'); local errors = {}
    for id, messageId in pairs(module) do
        local sucess, error = pcall(escape, self, id)

        if not sucess then
            errors[#errors + 1] = error
        end
    end

    local nlen = getn(errors)
    return nlen == 0 and true or nil, nlen ~= 0 and errors
end

local function closeThread(self, thread)
    local type1, type2 = type(self), type(thread)
    if type1 ~= 'table' then
        return error(format(bad, 'self', 'table', type1))
    elseif thread and type2 ~= 'number' then
        thread = tonumber(thread)
        if not thread then
            return error(format(bad, 1, 'number', type2))
        end
    end

    local thread = self._threads[thread]
    if thread then
        local sucess, error = close(thread)

        return sucess, error
    end
end

local function closeAllThreads(self)
    local type1 = type(self)
    if type1 ~= 'table' then
        return error(format(bad, 'self', 'table', type1))
    end

    local trds = self._threads
    if not trds then
        return nil, 'No currently seted thread(s).'
    end

    local errors = {}
    if trds ~= 0 then
        for n in ipairs(trds) do
            local s, e = self:closeThread(n)
            if not s then
                errors[n] = e
            end
        end
    end


    self._current_thread = self._current_thread and close(self._current_thread)

    local n = getn(errors)
    return n > 0 and errors
end

local function getRunningThread(self, thread)
    local type1, type2 = type(self), type(thread)
    if type1 ~= 'table' then
        return error(format(bad, 'self', 'table', type1))
    elseif thread and type2 ~= 'number' then
        return error(format(bad, 1, 'number', type2))
    end

    local trds = self._threads 
    if not trds then
        return nil, 'No currently seted thread(s).'
    end

    local current = self._current_thread
    if current then
        local status = status(current)
        if status == 'running' then
            return true
        end
    end

    if getn(trds) ~= 0 then
        for _, thread in ipairs(trds) do
            local status = status(thread)
            if status == 'running' then
                return true
            end
        end
    end

    return nil, 'No active threads.'
end

return {
    encode = encode, -- encode a table to be formated into json

    decode = decode, -- decode a converted table

    setSlot = setSlot, -- set a data store `slot` in

    getSlot = getSlot, -- get a seted data store `slot`

    quitSlot = quitSlot, -- remove a slot seted into this data store

    quitAllSlots = quitAllSlots, -- remove all seted slots into this data store

    closeThread = closeThread, -- close a thread

    closeAllThreads = closeAllThreads, -- close all threads

    getRunningThread = getRunningThread, -- get the current running thread
}