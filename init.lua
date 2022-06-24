do
	if (not table.find) then
		table.find = function(self, value, init)
			init = type(init) == "number" and init or 0
			for ind, val in next, self do
				if (ind > init) then
					if (val == value) then
						return ind
					end
				end
			end

			return nil
		end
	end
end

local json = require("json")
local request = require("coro-http").request

local modules = {}
local key = nil
local url = ("https://api.luawl.com/%s.php")
local key_statuses = {'Assigned','Unassigned','Disabled','Active'}

local function send_post(href, body)
	body.token = key

	local header, response = request("POST", url:format(href), {
		["Content-Type"] = "application/json"
	}, json.stringify(body))

	return table.pack(json.parse(response))[1]
end

-------------------------------------------

function modules:set_luawl_key(token)
	key = token
end

function modules:add_whitelist(discord_id, trial_hours, wl_script_id)
	local key = ""

	key = send_post("whitelistUser", { discord_id = discord_id, trial_hours = trial_hours, wl_script_id = wl_script_id })

	return key
end

function modules:delete_whitelist(discord_id)
	return send_post("deleteKey", { discord_id = discord_id })
end

function modules:reset_hwid(discord_id_or_key)
	local data = send_post("resetHWID", { wl_key = discord_id_or_key, discord_id = discord_id_or_key })
	return type(data) == "table" and data.error or data
end

function modules:get_whitelist(discord_id_or_key)
	local data = {
		wl_key = "",
		discord_id = 0,
		HWID = "",
		key_status = "",
		wl_script_id = 0,
		isTrial = false,
		hours_remaining = 0,
		expiration = nil
	}
	
	local response = send_post("getKey", {wl_key = discord_id_or_key, discord_id = discord_id_or_key})

	if (type(response) == "string") then
		return response
	end

	for key, value in next, response do data[key]=value end

	data.isTrial = data.isTrial == 1

	return data
end

function modules:add_blacklist(discord_id_or_key)
	return send_post("createBlacklist", { discord_id = discord_id_or_key, wl_key = discord_id_or_key })
end

function modules:remove_blacklist(discord_id_or_key)
	return send_post("removeBlacklist", { discord_id = discord_id_or_key, wl_key = discord_id_or_key })
end

function modules:disable_user_key(discord_id_or_key)
	return send_post("disableKey", { discord_id = discord_id_or_key, wl_key = discord_id_or_key })
end

function modules:is_on_cooldown(discord_id)
	return send_post("isOnCooldown", { discord_id = discord_id })
end

function modules:remove_cooldown(discord_id)
	return send_post("removeCooldown", { discord_id = discord_id })
end

--[[
	key_status: 'Assigned'|'Unassigned'|'Disabled'|'Active'
]]
function modules:update_key_status(discord_id, key_status)
	assert(table.find(key_statuses, tostring(key_status), ('Invalid key status, valid key status are: %s'):format(table.concat(key_statuses, ', '))))
	return send_post("updateKeyStatus", { discord_id = discord_id, status = key_status })
end

function modules:get_scripts()
	return send_post("getAccountScripts")
end

function modules:get_logs(discord_id_or_key_or_hwid)
	return send_post("getLogs", { wl_key = discord_id_or_key_or_hwid, discord_id = discord_id_or_key_or_hwid, HWID = discord_id_or_key_or_hwid })
end

function modules:get_buyer_role()
	return send_post("getBuyerRole", {})
end

return modules