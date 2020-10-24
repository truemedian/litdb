local module = {};

local resolveToNumber = function(str)
	local existing;
	pcall(function()
		existing = tonumber(str);
	end);
	return existing;
end

function module.run(authentication,input,callback)
	local run = function(input)
		if(type(input) == "number" or resolveToNumber(input) ~= nil) then
            api.request("https://users.roblox.com/v1/users/"..input,"GET",{},{},authentication)(function(response,body)
                if(response.code == 200) then 
                    pcall(function()
                        callback(json.decode(body)["name"]);
                    end)
                end
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