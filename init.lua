local stream = {}

-- Deps
local trycatch = require("trycatch")

local tableStream = {}

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

function tableStream:add(item)
    if self:contains(item) then
        return
    end

    self:set(item, {})
end

function tableStream:set(item, value)
    self.stream.__table[item] = value
end

function tableStream:remove(pos)
    for i, v in ipairs(self.stream.__table) do
        if pos == i then
            table.remove(self.stream.__table, i)
        end
    end
end

function tableStream:equals(tb)
    if self.stream.__table == tb then
        return true
    else
        return false
    end
end

function tableStream.stream:forEach(f)
    for item, value in pairs(self.__table) do
        f(value, item)
    end
end

function tableStream:contains(item)
    for i, v in ipairs(self.stream.__table) do
        if v == item then
            return true, self.stream.__table[item]
        else
            return false
        end
    end
end

function tableStream:isEmpty()
    if not next(self.stream.__table) then
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

function tableStream:indexOf(item)
    for i, v in ipairs(self.stream.__table) do
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

function tableStream:copy(tb1)
    for i, v in pairs(self.stream.__table) do
        table.insert(tb1, v)
    end
    local st = createStream(tb1)
    return st
end

function tableStream:size()
    local l = 0
    for i,v in pairs(self.stream.__table) do
        l = l + 1
    end
    return l
end

function tableStream:clear()
    local newTable = {}

    return createStream(newTable)
end

function tableStream:get(index)
    for i, v in ipairs(self.stream.__table) do
        if index == i then
            return v
        end
    end
end

return stream