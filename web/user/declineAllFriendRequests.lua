local module = {
	authenticationRequired = true;
};

local resolveToNumber = function(str)
	local existing;
	pcall(function()
		existing = tonumber(str);
	end);
	return existing;
end

function module.run(authentication, callback)
	api.request("https://users.roblox.com/v1/users/authenticated", "GET", {}, {}, authentication)(function(response, body)
		if (response.code == 200) then 
			local success, err = pcall(function()
				if (json.decode(body) ~= nil) then 
					local user = json.decode(body)["id"];
					local endpoint = "https://friends.roblox.com/v1/user/friend-requests/decline-all";

					api.getXCSRF(authentication, function(token)
						api.request(endpoint, "POST", {
							{
								"X-CSRF-TOKEN",
								token
							},
						}, {}, authentication)(function(response, body)
							pcall(function()
								if (response.code ~= 200) then 
									logger:log(1, json.encode(json.decode(body)["errors"]));
								end
								callback(response.code == 200, response);
							end)
						end);
					end);
				end
			end)

			if (err and not success) then 
				logger:log(1, err);
			end
		else
			logger:log(1, "Invalid user cookie!");
		end
	end);
end

return module;