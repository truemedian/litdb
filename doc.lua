--[=[
	Documentation Format:

	--[[@
		@file filename
		@desc description
		@param parameter<type,type> description
		@returns type|type description
	]]
]=]

string.split = function(str, pattern)
	local out, counter = { }, 0
	string.gsub(str, pattern, function(v)
		counter = counter + 1
		out[counter] = v
	end)
	return out
end

table.pairsByIndexes = function(list, f)
	local out = {}
	for index in next, list do
		out[#out + 1] = index
	end
	table.sort(out, f)
	
	local i = 0
	return function()
		i = i + 1
		if out[i] ~= nil then
			return out[i], list[out[i]]
		end
	end
end

local field = {
	["file"] = function(src, v)
		return v
	end,	
	["desc"] = function(src, v)
		src[#src + 1] = v
	end,
	["param"] = function(src, v)
		local name, types, description = string.match(v, "^([%w_]+%??)< *(.-) *> +(.-)$")
		local optional = string.sub(name, -1) == '?'

		src[#src + 1] = { (optional and string.sub(name, 1, -2) or name), string.split(types, "[^, ]+"), description, optional }
	end,
	["returns"] = function(src, v)
		local types, description = string.match(v, "^(%S+) +(.-)$")
		src[#src + 1] = { string.split(types, "[^|]+"), description }
	end
}

local _S = { }
local _T = { { }, { } }
local generate = function(fileName, content)
	local files = { }

	string.gsub(content, "%-%-%[%[@\r?\n(.-)%]%]\r?\n(.-)\r?\n", function(info, func)
		local data, f = { }
		for k, v in next, field do
			string.gsub(info, "@" .. k .. " (.-)\r?\n", function(j)
				if not data[k] then
					data[k] = { }
				end

				local n = v(data[k], j)
				if n then
					f = n
				end
			end)
		end

		local fn = string.match(func, "[%w_]+%.([%w_]+) ?= ?function")

		local file = { }
		local params = { }
		local hasParam = not not data.param
		if hasParam then
			for i = 1, #data.param do
				params[i] = data.param[i][1]
			end
		end

		local name = fn .. " ( " .. table.concat(params, ", ") .. " )"
		file[#file + 1] = ">### " .. name
		if hasParam then
			file[#file + 1] = ">| Parameter | Type | Required | Description |"
			file[#file + 1] = ">| :-: | :-: | :-: | - |"
			for i = 1, #data.param do
				file[#file + 1] = ">| " .. data.param[i][1] .. " | `" .. table.concat(data.param[i][2], "`, `") .. "` | " .. (data.param[i][4] and "✕" or "✔") .. " | " .. data.param[i][3] .. " |"
			end
			file[#file + 1] = '>'
		end

		file[#file + 1] = ">" .. (data.desc and table.concat(data.desc, "<br>\n>") or "No description.")

		if data.returns then
			file[#file + 1] = '>'
			file[#file + 1] = ">**Returns**"
			file[#file + 1] = '>'
			file[#file + 1] = ">| Type | Description |"
			file[#file + 1] = ">| :-: | - |"
			for i = 1, #data.returns do
				file[#file + 1] = ">| `" .. table.concat(data.returns[i][1], "`, `") .. "` | " .. data.returns[i][2] .. " |"
			end
			file[#file + 1] = ">\n"
		else
			file[#file + 1] = '\n'			
		end

		f = (f or "API")
		if not _S[f] then
			_S[f] = { }
		end
		_S[f][#_S[f] + 1] = file

		if not _T[2][f] then
			_T[2][f] = #_T[1] + 1
			_T[1][_T[2][f]] = { }
		end
		_T[1][_T[2][f]][#_T[1][_T[2][f]] + 1] = { string.match(name, "^(%S+)"), string.gsub(string.lower(name), "[ %(%),]", '-') }
	end)
end

local writeFile = function(file, data)
	local doc = io.open("docs/" .. tostring(file) .. ".md", "w+")
	doc:write("## Methods\n" .. data)
	doc:flush()
	doc:close()
end

for k, v in next, {
	"init"
} do
	local file = io.open(v .. ".lua", 'r')
	generate(v, file:read("*a"))
	file:close()
end

for k, v in next, _S do
	--local counter = 0
	for i = 1, #v do --for i, j in table.pairsByIndexes(v) do
		--counter = counter + 1
		v[i--[[counter]]] = table.concat(v[i]--[[j]], '\n')
	end
	_S[k] = table.concat(v, "\n \n")
end

for k, v in next, _S do
	writeFile(k, v)
end

local tree = { }

local tmp = { }
for k, v in next, _T[2] do
	tmp[v] = k
end

for i = 1, #_T[1] do
	tree[#tree + 1] = "- [" .. tmp[i] .. "](" .. tmp[i] .. ".md)"
	for j = 1, #_T[1][_T[2][tmp[i]]] do
		tree[#tree + 1] = "\t- [" .. _T[1][_T[2][tmp[i]]][j][1] .. "](" .. tmp[i] .. ".md#" ..  _T[1][_T[2][tmp[i]]][j][2] .. ")"
	end
end

local file = io.open("docs/README.md", 'r')
local readme = file:read("*a")
file:close()
readme = string.match(readme, "^(.-## Tree\n\n)")

file = io.open("docs/README.md", "w+")
file:write(readme .. table.concat(tree, "\n"))
file:flush()
file:close()