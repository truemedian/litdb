local module = {
    authenticationRequired = false;
};

function module.run(authentication,groupId,number,callback)
    local endpoint = "https://groups.roblox.com/v1/groups/"..groupId.."/roles";
	api.request(endpoint,"GET",{},{},authentication)(function(response,body)
		for _,role in pairs(json.decode(body)["roles"]) do
			if(role.rank == number) then 
				pcall(function()
					callback(role.id);
				end)
			end
		end
	end)
end

return module;