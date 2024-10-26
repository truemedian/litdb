--[[lit-meta
	name = 'er2off/dump'
	version = '1.0.0'
	homepage = 'https://github.com/er2off/lua-mods'
	description = 'Simple table dumping utility.'
	tags = {'lua', 'table', 'dump'}
	license = 'Zlib'
	author = {
		name = 'Er2',
		email = 'er2@dismail.de'
	}
]]

-- dump(table, depth?) - Return string that shows table contents.
local function dump(v, d)
	if type(d) ~= 'number' or d < 0
	then d = 0 end
	local e = (' '):rep(d)
	if type(v) == 'userdata'
	then return e.. '<USERDATA>'
	elseif type(v) ~= 'table'
	then return e.. tostring(v)
	end
	-- tables
	local c = '\n'
	for k, val in pairs(v)
	do c = c.. e..('%s = %s\n'):format(k, dump(val, d + 1))
	end
	return c
end
_G.dump = dump
