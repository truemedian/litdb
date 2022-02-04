local stream = {}

-- Deps
local trycatch = require("trycatch")

local tableStream = table

tableStream.stream = {}

local function createStream(t)
    tableStream.stream.__table = t

    return tableStream
end

function stream.createTableStream(t)
    local _v = createStream(nil)
    trycatch:TryCatch(function ()
        _v = createStream(t)
    end, function (err)
        error(err)
    end)
    return _v
end

function tableStream.stream:forEach(f)
    for item, value in pairs(self.__table) do
        f(value, item)
    end
end

function tableStream.stream:contains(item)
    for i, v in ipairs(self.__table) do
        if v == item then
            return true, self.__table[item]
        else
            return false
        end
    end
end

function tableStream.stream:isEmpty()
    if not next(self.__table) then
        return true
    else
        return false
    end
end

function tableStream.stream:filter(f)
    local instanceOfTable = {}

    for k, v in pairs(self.__table) do
        if f(v) then
            table.insert(instanceOfTable, v)
        end
    end

    return createStream(instanceOfTable).stream
end

function tableStream.stream:indexOf(item)
    for i, v in ipairs(self.__table) do
        if v == item then
            return i
        end
    end
end

function tableStream.stream:find(f)
    for i, v in ipairs(self.__table) do
        if f(v, i, self.__table) then
            return v
        end
    end
end

function tableStream.stream:findIndex(f)
    for i, v in ipairs(self.__table) do
        if f(v, i, self.__table) then
            return i
        end
    end
end

function tableStream.stream:copy(tb1)
    for i, v in pairs(self.__table) do
        table.insert(tb1, v)
    end
    local st = createStream(tb1)
    return st
end

function tableStream.stream:size()
    local l = 0
    for i,v in pairs(self.__table) do
        l = l + 1
    end
    return l
end

function tableStream.stream:clear()
    for i, v in ipairs(self.__table) do
        table.remove(self.__table, i)
    end
end

function tableStream.stream:get(index)
    for i, v in ipairs(self.__table) do
        if index == i then
            return v
        end
    end
end

function tableStream.stream:removeIf(f)
    for i, v in ipairs(self.__table) do
        if f(v, i, self.__table) then
            table.remove(self.__table, i)
            return true
        else
            return false
        end
    end
end

return stream