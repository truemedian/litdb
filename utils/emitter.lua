local enum = require("./enum")
local module = {}
local list = {}

module.get = function(self, Name)
    if not list[Name] then
        list[Name] = {}
    end

    return {
        on = function(id, fn)
            if not id then return end

            if not list[Name][id] then
                list[Name][id] = {}
            end

            table.insert(list[Name][id], fn)
        end,
        emit = function(id, ...)
            if not id then return end

            if not list[Name][id] then
                list[Name][id] = {}
            end

            for i, v in pairs(list[Name][id]) do
                v(...)
            end
        end
    }
end

return module