local dels = {
	["remove"] = function(id)
		return Request("DELETE", "https://api.paste.ee/v1/pastes/", nil, id)
	end
}

local function Delete(aim, ...)
	if dels[aim] then
		return dels[aim](...)
	else
		error("Invalid Delete aim '"..aim.."'.")
	end
end

return Delete