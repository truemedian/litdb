local module = {
    authenticationRequired = false;
};

function module.run(authentication,groupId,callback)
    local endpoint = "https://groups.roblox.com/v1/groups/"..groupId.."/roles";
	api.request(endpoint,"GET",{},{},authentication)(function(response,body)
		pcall(function()
			callback(json.decode(body)["roles"]);
		end)
	end)
end

return module;