return function (object, advanced)
    local object_type = type(object)

    if object_type == "table" then
        if advanced and object.Class ~= nil then
            return object.Class
        end

        if getmetatable(object) then
            return "metatable"
        end
    end

    return object_type
end