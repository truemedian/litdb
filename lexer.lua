local h, i=':":', ':";'

local function lexer(code)
	code, z= " " .. string.gsub(code, "\n", " ") .. " "
	local a={}
	local b={}
	local c={}
	local d={}
	local e=0
	for f in string.gmatch(code, h .. '(.-)' .. i) do
		table.insert(a, {f})
	end
	for f in string.gmatch(code, '([^%s]+)') do
		if tonumber(f, 10) then
			if not (string.sub(f, 1, 2)=="0x") then
				f=tonumber(f, 10)
			end
		end
		table.insert(b, f)
	end
	if a~={} then
		for g=1, #b do
			if string.sub(b[g], 1, #h)==h then
				table.insert(d, g-#c+e)
				e=e+1
				for f=g, #b do
					table.insert(c, 1, f)
					if string.sub(b[f], -1*#i)==i then break end
				end
			end
		end
		for g=1, #c do
			table.remove(b, c[g])
		end
		for g=1, #d do
			table.insert(b, d[g], a[g])
		end
	end
	return b
end

return lexer