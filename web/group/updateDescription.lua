local module = {
    authenticationRequired = true;
};

function module.run(authentication,groupId,description,callback)
    api.getXCSRF(authentication,function(token)
        local endpoint = "https://groups.roblox.com/v1/groups/"..groupId.."/description";
        api.request(endpoint,"PATCH",{
            {"Content-Type","application/json"};
            {"X-CSRF-TOKEN",token};
        },{description = description or "N/A"},authentication)(function(response,body)
            pcall(function()
                callback(response.code==200,response,json.decode(body));
            end)
        end)
    end)
end

return module;