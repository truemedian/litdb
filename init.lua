local stream = {}

local tableStream = table

tableStream.stream = {}

function stream.createTableStream(table)
    tableStream.stream.__table = table
    return tableStream
end

function tableStream.stream:forEach(f)
    for item, value in pairs(self.__table) do
        f(value, item)
    end
end

function tableStream.stream:contains(item)
    if self.__table[item] then
        return true
    else
        return false
    end
end

function tableStream.stream:isEmpty()
    if not next(self.__table) then
        return true
    else
        return false
    end
end

return stream