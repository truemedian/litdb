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

function module.run(authentication,groupId,input,callback)
    local run = function(input)
        if(type(input) == "number" or resolveToNumber(input) ~= nil) then
            local userId = input;
            api.getXCSRF(authentication,function(token)
                local endpoint = "https://groups.roblox.com/v1/groups/"..groupId.."/users/"..userId;
                api.request(endpoint,"DELETE",{
                    {"X-CSRF-TOKEN",token};
                },{},authentication)(function(response,body)
                    pcall(function()
                        callback(response.code==200,response,json.decode(body));
                    end)
                end)
            end)
        else
            logger:log(1,"Invalid userId (user doesn't exist)");
        end
    end

    if(resolveToNumber(input) ~= nil or type(input) == "number") then 
        run(input);
    else
        api.request("https://api.roblox.com/users/get-by-username?username="..input,"GET",{},{},authentication)(function(response,body)
			if(response.code == 200) then 
				run(json.decode(body)["Id"]);
            else
                logger:log(1,"Invalid username provided.") 
            end
        end)
    end 
end

return module;