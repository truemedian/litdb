local _typeof = require("./TypeOf")
local _pluralize = require("./Pluralize")

local function find(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
end

return function (param, allowedTypes, required, throwError, characterLimit)
    local value_t = _typeof(param[2], true)

    local Passed = false
    local ErrorMessage

    if value_t == "nil" and required then
        ErrorMessage = "The parameter '"..param[1].."' is required."
    elseif value_t == "nil" and not required then
        return
    end

    for _, allowedType in ipairs(allowedTypes) do
        if value_t == allowedType then
            Passed = true
            break
        end
    end

    if not Passed then
        local formattedTypes = allowedTypes[1]
		local typesLength = #allowedTypes

        if typesLength == 2 then
			formattedTypes = table.concat(allowedTypes, " or ")
		elseif typesLength > 2 then
			allowedTypes[typesLength] = "or " .. allowedTypes[typesLength]
			formattedTypes = table.concat(allowedTypes, ", ")
		end

        local formatted = string.format("The parameter '%s' must be a %s value. (got %s)", param[1], formattedTypes, value_t)
		
		if not (throwError) then
			print(formatted)
			return
		end
		
		error(formatted)
    end

    if find(allowedTypes, "string") and value_t == "string" and characterLimit then
		local stringLength = string.len(param[2])
		
		local minimum = characterLimit[1]
		local maximum = characterLimit[2]
		
		if (stringLength < minimum) then
			ErrorMessage = string.format("The parameter '%s' must be at least %i %s.", param[1], minimum, _pluralize("character", minimum))
		elseif (stringLength > maximum) then
			ErrorMessage = string.format("The parameter '%s' cannot exceed %i %s.", param[1], maximum, _pluralize("character", maximum))
		end
	end

    if ErrorMessage then
        if not throwError then
            print(ErrorMessage)
        else
            error(ErrorMessage)
        end
    end

end