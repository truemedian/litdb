Delete = class('Delete')
Delete.__description = "DELETE method for Paste.ee API."

local dels = {
	["submit"] = function(id)
	return(
			Request(
				"DELETE",
				"https://api.paste.ee/v1/pastes/",
				nil,
				id
			)
		)
	end
}

function Delete:__init(aim, ...)
	if dels[aim] then
		return dels[aim](...)
	else
		error("Invalid Delete aim '"..aim.."'.")
	end
end

return Delete