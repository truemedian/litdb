local json = require('json')
local http = require('coro-http')

local function request(method, url, headers, body)

	if type(url) == 'table' then
		url = table.concat(url, '/')
	end
	
	local tbl = {}
	for k, v in pairs(headers) do
		table.insert(tbl, {k, v})
	end
	headers = tbl

	if body then
		body = json.encode(body)
		table.insert(headers, {'Content-Length', body:len()})
	end

	local res, data = http.request(method, url, headers, body)
	assert(res.code > 199 and res.code < 300, res.reason)
	return json.decode(data)

end

local function camelify(obj)

	if type(obj) == 'string' then

		local str, count = obj:lower():gsub('_.', string.upper):gsub('_', '')
		return str

	elseif type(obj) == 'table' then
	
		local tbl = {}
		for k, v in pairs(obj) do
			tbl[camelify(k)] = camelify(v)
		end
		return tbl

	end

	return obj

end

return {
	request = request,
	camelify = camelify
}
