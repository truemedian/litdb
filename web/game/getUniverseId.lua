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

function module.run(authentication,placeId,callback)
    local endpoint = "https://www.roblox.com/places/api-get-details?assetId="..placeId;

    api.request(endpoint,"GET",{},{},authentication)(function(response,body)
        if(response.code == 200) then 
            pcall(function()
                callback(json.decode(body)["UniverseId"])
            end)
        else
            logger:log(1,"Invalid placeId!");
        end
    end)
end

return module;