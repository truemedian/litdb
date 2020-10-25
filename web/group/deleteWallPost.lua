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

function module.run(authentication,groupId,postId,callback)
    api.getXCSRF(authentication,function(token)
        local endpoint = "https://groups.roblox.com/v1/groups/"..groupId.."/wall/posts/"..postId;
        api.request(endpoint,"DELETE",{
            {"X-CSRF-TOKEN",token};
        },{},authentication)(function(response,body)
            pcall(function()
                callback(response.code==200,response,json.decode(body));
            end)
        end)
    end)
end

return module;