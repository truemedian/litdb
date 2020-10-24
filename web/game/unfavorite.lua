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

function module.run(authentication,placeId,callback)
    local endpoint = "https://www.roblox.com/places/api-get-details?assetId="..placeId;

    api.request(endpoint,"GET",{},{},authentication)(function(response,body)
        if(response.code == 200) then 
            local id = json.decode(body)["UniverseId"];
            local endpoint = "https://games.roblox.com/v1/games/"..id.."/favorites";
            api.getXCSRF(authentication,function(token)
                api.request(endpoint,"POST",{
                    {"X-CSRF-TOKEN",token},
                    {"Content-Type","application/json"}
                },{
                    isFavorited = false;
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
            logger:log(1,"Invalid placeId!");
        end
    end)
end

return module;