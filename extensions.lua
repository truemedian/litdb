function _G.printf(...)
	return print(string.format(...))
end

-- table --

function table.count(tbl)
	local n = 0
	for k, v in pairs(tbl) do
		n = n + 1
	end
	return n
end

function table.deepcount(tbl)
	local n = 0
	for k, v in pairs(tbl) do
		n = type(v) == 'table' and n + table.deepcount(v) or n + 1
	end
	return n
end

function table.find(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
end

function table.reverse(tbl)
	local new = {}
	for i = #tbl, 1, -1 do
		table.insert(new, tbl[i])
	end
	return new
end

function table.copy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = v
	end
	return new
end

function table.deepcopy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = type(v) == 'table' and table.deepcopy(v) or v
	end
	return new
end

function table.keys(tbl)
	local keys = {}
	for k in pairs(tbl) do
		table.insert(keys, k)
	end
	return keys
end

function table.values(tbl)
	local values = {}
	for _, v in pairs(tbl) do
		table.insert(values, v)
	end
	return values
end

-- string --

function string.split(str)
	local words = {}
	for word in string.gmatch(str, '%S+') do
		table.insert(words, word)
	end
	return words
end

-- math --

function math.clamp(n, min, max)
	return math.min(math.max(n, min), max)
end

function math.round(n, i)
	local m = 10^(i or 0)
	return math.floor(n * m + 0.5) / m
end
