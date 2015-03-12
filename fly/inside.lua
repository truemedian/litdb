--
--    lua.inside - eRuby-like templating engine for Lua
--    Copyright (c) 2015 zyxwvu Shi <imzyxwvu@icloud.com>
--

local inside = { "view engine" }

inside.state_meth = {}
inside.state_mt = { __index = inside.state_meth }

local function trim_string(str)
	return str:gsub("[%s\t]*$", ""):match "^[%s\t]*(.*)"
end

local function trim_string_nl(str)
	return str:gsub("[\r\n]*$", ""):match "^[\r\n]*(.*)"
end

function inside.state_meth:write(str)
	self[1][#self[1] + 1] = ("write\"%s\""):format(
		string.gsub(trim_string_nl(str), "[\\\"\n\r]", {
			["\n"] = "\\n", ["\r"] = "\\r",
			["\\"] = "\\\\", ["\""] = "\\\""
		}))
end

function inside.state_meth:print(str)
	self[1][#self[1] + 1] = ("write(%s)"):format(trim_string(str))
end

function inside.state_meth:inline(str)
	self[1][#self[1] + 1] = trim_string(str)
end

function inside.state_mt:__tostring()
	return table.concat(self[1], "\n")
end

function inside.state()
	local state = { {} }
	return setmetatable(state, inside.state_mt)
end

function inside.compile(source)
	assert(type(source) == "string")
	local state, position, parsing = inside.state(), 1, "raw"
	local inline_begin_position
	local assist_stack = {} -- used to check parenthess closing
	local inline_begin_stack_position
	while true do
		if parsing == "raw" then -- parsing plain content
			local l, r = source:find("<%", position, true)
			if l and r then -- going to inline code
				state:write(source:sub(position, l - 1))
				parsing, position = "lua", r + 1
				inline_begin_position = position
				inline_begin_stack_position = #assist_stack
			else break end
		elseif parsing == "comment" then -- parsing html comment to ignore ( TODO )
			local l, r = source:find("-->", position, true)
			if l and r then
				parsing, position = "raw", r + 1
			else break end
		elseif parsing == "lua" then -- parsing embeded Lua code
			local l, r, mark = source:find("([%%%[\"\'%(%)%{%}])", position)
			if mark == "\"" then
				parsing, position = "str2", r + 1
			elseif mark == "'" then
				parsing, position = "str1", r + 1
			elseif mark == "(" or mark == "{" then
				-- TODO: Ignore parenthess inside comments (:
				assist_stack[#assist_stack + 1] = { mark, position }
				position = r + 1
			elseif mark == "}" then
				assert(assist_stack[#assist_stack][1] == "{", "'{' not paired")
				assist_stack[#assist_stack], position = nil, r + 1
			elseif mark == ")" then
				assert(assist_stack[#assist_stack][1] == "(", "'(' not paired")
				assist_stack[#assist_stack], position = nil, r + 1
			else
				r = r + 1 -- extend token length
				local nc = source:sub(r, r)
				if mark == "[" and (nc == "=" or nc == "[") then
					error "attempt to embed blobs inside Lua chunks"
				elseif mark == "%" and nc == ">" then -- close mark
					if l - 1 >= position then
						local chunk = source:sub(inline_begin_position, r - 2)
						if chunk:sub(1, 1) == "=" then
							assert(
								inline_begin_stack_position == #assist_stack,
								"parentheses not paired")
							state:print(chunk:sub(2, -1))
						else
							state:inline(chunk)
						end
					end
					parsing, inline_begin_position, r = "raw", nil, r + 1
				end
				position = r
			end
		elseif parsing == "str2" then -- string wrapped with "
			local l, r, token = source:find("(\\?\")", position)
			if l and r then
				if token == "\"" then parsing = "lua" end
				position = r + 1
			else break end
		elseif parsing == "str1" then -- string wrapped with '
			local l, r, token = source:find("(\\?')", position)
			if l and r then
				if token == "'" then parsing = "lua" end
				position = r + 1
			else break end
		else error "never reaches here" end
	end
	assert(#assist_stack == 0, "parentheses not paired")
	assert(parsing ~= "lua", "embeded code not closed")
	assert(parsing == "raw", "embeded string not closed")
	if position <= #source then
		state:write(source:sub(position, -1))
	end
	return assert(load(tostring(state), "generated template", "t"))
end

function inside.render(template, data) -- doesn't work with Lua 5.2
	local global, buffer = {}, {}
	local function write(str)
		buffer[#buffer + 1] = str
	end
	setfenv(template, setmetatable({}, {
		__index = function(self, k)
			return k == "write" and write or global[k] or data[k]
		end,
		__newindex = function(self, k, v)
			global[k] = v
		end
	}))
	template()
	return table.concat(buffer)
end

return inside
