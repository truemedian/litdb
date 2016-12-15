local posts = {
	["submit"] = function(encrypt, description, sections)
	local submitedPaste = {
		["encrypt"] = encrypt or false,
		["description"] = description or " ",
		["sections"] = {AdaptToUrl(sections)}
	} 
		return Request("POST", "https://api.paste.ee/v1/pastes", nil, query.stringify(submitedPaste))
	end,
	["auth"] = function(username, password)
	local user = {
		["username"] = username,
		["password"] = password
	} 
		return equest("POST", "https://api.paste.ee/v1/users/authenticate", nil, query.stringify(user))	
	end
}

function Post:(aim, ...)
	if posts[aim] then
		return posts[aim](...)
	else
		error("Invalid Post aim '"..aim.."'.")
	end
end


return Post