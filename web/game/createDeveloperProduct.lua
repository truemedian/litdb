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

function module.run(authentication,placeId,details,callback)
    local endpoint = "https://www.roblox.com/places/api-get-details?assetId="..placeId;
    local querystring = require("querystring");

    api.request(endpoint,"GET",{},{},authentication)(function(response,body)
        if(response.code == 200) then 
            local id = json.decode(body)["UniverseId"];
            local endpoint = "https://develop.roblox.com/v1/universes/"..id.."/developerproducts";
            local price = details.price or 1;
            local description = details.description or "N/A";
            local name = details.name or "N/A";
            local endpoint = endpoint.."?"..querystring.stringify({
                name = name;
                description = description;
                priceInRobux = price;
            },nil,nil,{encodeURIComponent = "gbkEncodeURIComponent"})

            api.getXCSRF(authentication,function(token)
                api.request(endpoint,"POST",{
                    {"X-CSRF-TOKEN",token},
                    {"Content-Type","application/json"}
                },{},authentication)(function(response,body)
                    if(response.code == 200) then 
                        pcall(function()
                            callback(true,json.decode(body)["shopId"]);
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