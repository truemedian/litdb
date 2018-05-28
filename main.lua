local http = require("./request")
local json = require('./json')
local meta = require("./package")
local api = {}

function api:getUsernameFromId(id)
	if type(id) ~= "integer" then return error(id.." is not an integer. Make sure it is the player id.") end

	return request:getJson("https://api.roblox.com/users/"..tostring(id)).Username
end


function api:getIdFromUsername(username)
	if type(user) ~= "string" then return error(username.." is not a string. Make sure it is the player's name.") end

	return request:getJson("https://api.roblox.com/users/get-by-username?username="..username).Id
end


--group functions
local groupApi  = {}
local object    = {}

function groupApi.group(id)
	object = {
		name = "h",
		desc = "",
		id = 0,

		members = 0,
		owner = {
			name = "",
			id = 0,
		},

		ranks = {
			{
				name = "Owner",
				rank = 255,
				desc = "The holder."
			}
		}			
	}

	function object:getRanks()
		return object.ranks
	end

	function object:getOwner()
		return object.owner
	end

	function object:getPlayerRank(playerId)
		return request:get("https://assetgame.roblox.com/Game/LuaWebService/HandleSocialRequest.ashx?method=GetGroupRole&playerid="..playerId.."&groupid=3"..object.id)
	end

	return object
end




return groupApi,userApi