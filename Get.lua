Get = class('Get')
Get.__description = "GET method for Paste.ee API."

local gets = {
	["listPastes"] = function(perpage, page)
	local __ = {
		["perpage"] = perpage,
		["page"] = page
	}
		return(
			Request(
				"GET",
				"https://api.paste.ee/v1/pastes",
				nil,
				query.stringify(__)
			)
		)
	end,
	["paste"] = function(id)
		return(
			Request(
				"GET",
				"https://api.paste.ee/v1/pastes/",
				nil,
				id
			)
		)
	end,
	["syntaxes"] = function(id)
	local ____ = id or ""
		return(
			Request(
				"GET",
				"https://api.paste.ee/v1/syntaxes"
				nil,
				____
			)
		)
	end,
	["key"] = function()
		return(
			Request(
				"GET",
				"https://api.paste.ee/v1/users/info"
			)
		)
	end,
}

function Get:__init(aim, ...)
	if gets[aim] then
		return gets[aim](...)
	else
		error("Invalid Get aim '"..aim.."'.")
	end
end

return Get