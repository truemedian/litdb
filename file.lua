-- Multipart (form-data) implementation
-- (c) Er2 2025 <er2@dismail.de>
-- Zlib License

--[[lit-meta
	name = 'er2off/multipart'
	version = '1.0.0'
	homepage = 'https://github.com/er2off/lua-mods'
	description = 'Multipart (form-data) implementation'
	tags = {'lua', 'http', 'multipart'}
	license = 'Zlib'
	author = {
		name = 'Er2',
		email = 'er2@dismail.de'
	}
]]

local mp = {
	CHARSET = 'UTF-8',
	LANGUAGE = '',
}

-- Generates boundary
function mp.boundary()
	local ret = {'BOUNDARY-'}
	for i = 2, 17
	do ret[i] = string.char(math.random(65, 90))
	end
	ret[18] = '-BOUNDARY'
	return table.concat(ret)
end

-- Transforms string to URL-friendly view
-- https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
function mp.urlencode(url)
	if url == nil then return end
	url = url:gsub('\n', '\r\n')
	url = url:gsub('([^%w_%- . ~])', function(c) return string.format('%%%02X', string.byte(c)) end)
	url = url:gsub(' ', '+')
	return url
end

local function printHead(ret, k, v)
	local str = {
		'Content-Disposition: form-data',
		'name="'..k..'"'
	}
	if type(v) == 'table' then
		if v.filename then
			table.insert(str, 'filename="'..(v.filename)..'"')
			table.insert(str, 'filename*='
				.. mp.CHARSET .."'".. mp.LANGUAGE .."'"
				.. mp.urlencode(v.filename))
		end
		table.insert(ret, table.concat(str, '; '))

		local contentType = v.contentType or 'application/octet-stream'
		table.insert(ret, 'Content-Type: '.. contentType)
	else
		table.insert(ret, table.concat(str, '; '))
	end

	table.insert(ret, '')
end

-- Main function: encodes parameters (table) to body (string)
function mp.encode(body)
	local bound = mp.boundary()
	local ret = {}
	for k, v in pairs(body) do
		table.insert(ret, '--'.. bound)
		printHead(ret, k, v)
		if type(v) == 'table'
		then table.insert(ret, tostring(v.data))
		else table.insert(ret, tostring(v))
		end
	end
	table.insert(ret, '--'.. bound ..'--')
	return table.concat(ret, '\r\n'), bound
end

return mp
