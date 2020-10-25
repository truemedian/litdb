local module = {
    authenticationRequired = false;
};

local resolveToNumber = function(str)
    local existing;
    pcall(function()
        existing = tonumber(str);
    end);
    return existing;
end

function module.run(authentication,userId,callback)
    local run = function(userId)
        if(type(userId) == "number" or resolveToNumber(userId) ~= nil) then 
            api.request("https://users.roblox.com/v1/users/"..userId,"GET",{},{},authentication)(function(response,body)
                if(response.code == 200) then 
                    pcall(function()
                        callback(json.decode(body));
                    end)
                else 
                    logger:log(1,"Invalid user!");
                end
            end);
        else
            logger:log(1,"Invalid int provided for `userId`")
        end
    end

    if(resolveToNumber(userId) ~= nil or type(userId) == "number") then 
        run(userId);
    else
        api.request("https://api.roblox.com/users/get-by-username?username="..userId,"GET",{},{},authentication)(function(response,body)
            if(response.code == 200) then 
                run(json.decode(body)["Id"]);
            else
                logger:log(1,"Invalid username provided.") 
            end
        end)
    end
end

return module;