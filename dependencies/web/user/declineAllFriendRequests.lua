
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

function module.run(authentication,callback)
	local endpoint = "https://friends.roblox.com/v1/user/friend-requests/decline-all";
	local response,body = api.request("POST",endpoint,{
        {"Content-Length",0};
    },{},authentication,true,true)
	if(response.code == 200) then 
		return true,response;
	else 
		logger:log(1,"Something went wrong.");
        return false,response;
	end
end

return module;