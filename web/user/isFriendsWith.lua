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

function module.run(authentication,user1,user2,callback)
    client.functions.resolveToUserId(user1,function(userId)
        client.functions.resolveToUserId(user2,function(userId2)
            local endpoint = "https://friends.roblox.com/v1/users/"..userId.."/friends/statuses?userIds="..userId2;
            api.request(endpoint,"GET",{},{},authentication)(function(response,body)
                if(response.code == 200) then 
                    pcall(function()
                        callback(json.decode(body)["data"][1]["status"] == "Friends");
                    end)
                else 
                    logger:log(1,"Invalid user!");
                end
            end);
        end)
    end)
end

return module;