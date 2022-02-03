local stream = {}

local tableStream = table

tableStream.stream = {}

local function createStream(t)
    tableStream.stream.__table = t
    return tableStream
end

function stream.createTableStream(table)
    return createStream(table)
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
    for i, v in ipairs(self.__table) do
        table.insert(instanceOfTable, v)
    end
    for i, v in ipairs(self.__table) do
        if f(v) then
        else
            table.remove(instanceOfTable, i)
        end
    end
    return createStream(instanceOfTable).stream
end

return stream