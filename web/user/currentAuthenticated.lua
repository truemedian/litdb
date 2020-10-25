local module = {
    authenticationRequired = true;
};

function module.run(authentication,callback)
    api.request("https://users.roblox.com/v1/users/authenticated","GET",{},{},authentication)(function(response,body)
        if(response.code == 200) then 
            local success,err = pcall(function()
                callback(json.decode(body));
            end)

            if(err and not success) then 
                logger:log(1,err);
            end
        else
            logger:log(1,"Invalid user cookie!");
        end
    end);
end

return module;