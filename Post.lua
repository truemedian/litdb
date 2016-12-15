Post = class('Post')
Post.__description = "POST method for Paste.ee API."

local posts = {
	["submit"] = function(encrypt, description, sections)
	local submitedPaste = {
		["encrypt"] = encrypt or false,
		["description"] = description or " ",
		["sections"] = {AdaptToUrl(sections)} -- Array
	} 
	--[[
		SECTIONS
	name : optional
	syntax : optional
	contents: not optional
	]]
		return
			Request(
				"POST",
				"https://api.paste.ee/v1/pastes",
				nil,
				query.stringify(submitedPaste)
			)
	end,
	["auth"] = function(username, password)
	local user = {
		["username"] = username,
		["password"] = password
	} 
		return
			Request(
				"POST",
				"https://api.paste.ee/v1/users/authenticate",
				nil,
				query.stringify(user)
			)
		
	end,
}

function Post:__init(aim, ...)
	if posts[aim] then
		return posts[aim](...)
	else
		error("Invalid Post aim '"..aim.."'.")
	end
end

return Post