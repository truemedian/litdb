local util = {}

local function format(tbl)
	if type(tbl) ~= 'table' then return end
	for i,v in pairs(tbl) do
		tbl[i] = v[1]
	end
	return tbl
end

function util.getGuildSettings(id, conn)
	if not id then return {} end
	local settings = conn:exec('SELECT * FROM guild_settings WHERE guild_id=' .. id .. ';', 'k')
	return format(settings)
end

return util