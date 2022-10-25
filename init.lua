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
local hasattr = function(table, key) return type(rawget(table, key)) ~= 'nil' end
local delattr = function(table, key) rawset(table, key, nil) end

local modules = {}
local key = nil
local url = ("https://api.luawl.com/%s.php")
local key_statuses = {'Assigned','Unassigned','Disabled','Active'}
local len = string.len

local function send_post(href, body)
	body.token = key

	if hasattr(body, 'HWID') and len(body.HWID) <= 40 then
		delattr(body, 'HWID')
	end

	if hasattr(body, 'discord_id') and len(body.discord_id) >= 20 then
		delattr(body, 'discord_id')
	end

	if hasattr(body, 'wl_key') and len(body.wl_key) ~= 40 then
		delattr(body, 'wl_key')
	end

	local header, response = request("POST", url:format(href), {
		{ "Content-Type", "application/json" },
		{ "User-Agent", "node-fetch" }
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
	return send_post("deleteKey", { discord_id = discord_id, wl_key = discord_id })
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

function modules:is_on_cooldown(discord_id_or_key)
	return send_post("isOnCooldown", { discord_id = discord_id_or_key, wl_key = discord_id_or_key })
end

function modules:remove_cooldown(discord_id_or_key)
	return send_post("removeCooldown", { discord_id = discord_id_or_key, wl_key = discord_id_or_key })
end

--[[
	key_status: 'Assigned'|'Unassigned'|'Disabled'|'Active'
]]
function modules:update_key_status(discord_id_or_key, key_status)
	assert(table.find(key_statuses, tostring(key_status), ('Invalid key status, valid key status are: %s'):format(table.concat(key_statuses, ', '))))
	return send_post("updateKeyStatus", { discord_id = discord_id_or_key, wl_key = discord_id_or_key, status = key_status })
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

function modules:add_key_tags(discord_id_or_key, tags, wl_script_id)
	assert(type(tags) == "table", ('`tags` must be a table (got `%s`)'):format(type(tags)))
	return send_post("addKeyTags", {
		wl_key = discord_id_or_key,
		discord_id = discord_id_or_key,
		tags = tags,
		wl_script_id = wl_script_id
	})
end

function modules:get_account_stats()
	local data = send_post("getAccountStats", {})

	if (type(data) == "table") then
		for key, value in next, data do
			if (type(value) == "string") then
				local values = table.pack(value:match('(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'))
				if (#values == 6) then
					data[key] = os.date("!*t", os.time({
						year = table.remove(values, 1),
						month = table.remove(values, 1),
						day = table.remove(values, 1),
						hour = table.remove(values, 1),
						min = table.remove(values, 1),
						sec = table.remove(values, 1)
					}))
				else
					local n = tonumber(value)
					data[key] = type(n) ~= "number" and value or n
				end
			end
		end
	end

	return data
end

return modules