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

copyTable = function(tbl)
    local copy = {};
    for k,v in pairs(tbl) do 
        if(type(v) == "table") then 
            copyTable(v);
        else 
            copy[k] = v;
        end
    end
    return copy;                
end 

function module.run(authentication,userId,callback)
    local run = function(userId)
        if(type(userId) == "number" or resolveToNumber(userId) ~= nil) then
            api.getXCSRF(authentication,function(token)
                local endpoint = "https://www.roblox.com/userblock/blockuser";
                api.request(endpoint,"POST",{
                    {"X-CSRF-TOKEN",token},
                    {"Content-Type","application/json"}
                },{
                    blockeeId = tostring(userId);
                },authentication)(function(response,body)
                    if(response.code == 200) then 
                        pcall(function()
                            callback(true,response);
                        end)
                    else 
                        logger:log(1,"Something went wrong.");
                        pcall(function()
                            callback(false,response);
                        end)
                    end
                end);
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