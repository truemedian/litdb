local http = require("./request")
local json = require('./json')
local meta = require("./package")
local request = require("./request")

local function wait(int)
	local startTime = os.time()
	local endTime   = startTime + int

	while (endTime ~= os.time()) do end
end

local function request(link)
	return coroutine.wrap(function()
		local res, id = http.request("GET", link)

		return id
	end)()
end

local api = {}

--user functions
function api:getUsernameFromId(id)
	if type(id) ~= "number" then return error(id.." is not an integer. Make sure it is the player id.") end

	coroutine.wrap(function()
		local res, id = http.request("GET", "https://api.roblox.com/users/"..tostring(id))
		return id.Id
	end)()
	return 
end


function api:getIdFromUsername(username)
	if type(user) ~= "string" then return error(username.." is not a string. Make sure it is the player's name.") end

	return json.decode(request("https://api.roblox.com/users/get-by-username?username="..username)).Id
end


--group functions
-- function api.group(id)
-- 	if type(id) ~= "number" then return error(id.." is not an integer, therefore it's not a group id. Make sure it is a group id.") end
-- 
-- 	local info = request("https://api.roblox.com/groups/"..id)--json.decode(request("https://api.roblox.com/groups/333"))
-- 	if info.Errors then return error(id.." is not a valid group id.") end
-- 
-- 	local object = {
-- 		name = info.Name,
-- 		desc = info.Description,
-- 		id = info.Id,
-- 
-- 		owner = {
-- 			name = info.Owner.Name,
-- 			id = info.Owner.Id,
-- 		},
-- 
-- 		ranks = info.Ranks
-- 	}
-- 
-- 	function object:getRanks()
-- 		return object.ranks
-- 	end
-- 
-- 	function object:getOwner()
-- 		return object.owner
-- 	end
-- 
-- 	function object:getPlayerRank(playerId)
-- 		return request:get("https://assetgame.roblox.com/Game/LuaWebService/HandleSocialRequest.ashx?method=GetGroupRole&playerid="..playerId.."&groupid="..object.id)
-- 	end
-- 
-- 	return object
-- end

function api:getAssetInformation(id)
	if type(id) ~= "number" then return error(id.." is not an integer.") end

	local info = request:getJson("http://api.roblox.com/Marketplace/ProductInfo?assetId=1818")

	local object = {
		assetId = info.AssetId,
		productId = info.ProductId,
		name = info.Name,
		desc = info.Description,
		creator = {
			info.Creator.Id,
			info.Creator.Name,
		},
		price = info.PriceInRobux,
		sales = info.Sales,
		isNew = info.IsNew,
		isForSale = info.IsForSale,
		isLimited = info.IsLimited,
		isLimitedUnique = info.IsLimitedUnique,
		remaining = info.Remaining,
	}

	return object
end

function api:ownsAsset(playerId, assetId)
	if type(playerId) ~= "number" or type(assetId) ~= "number" then return error("The argument is not an integer.") end
	
	local a = request:getJson("https://api.roblox.com/Ownership/HasAsset?userId="..playerId.."&assetId="..assetId)

	return a
end

function api:isUsernameTaken(username)
	local a = request:get("http://www.roblox.com/UserCheck/DoesUsernameExist?username="..username)

end

return api