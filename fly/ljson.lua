-- This is still a slow JSON implement.
-- If possible I would add lua-cjson backend.

local encoders = {}

local function encode(object)
	return assert(
		encoders[type(object)],
		"can't encode object"
		)(object)
end

function encoders.string(s)
	return string.format("\"%s\"", s:gsub(
		"([\\\"\'\r\n])", {
			["\\"] = "\\\\", ["\""] = "\\\"", ["\'"] = "\\\'",
			["\r"] = "\\r", ["\n"] = "\\n" }))
end

function encoders.number(n)
	return tostring(n)
end

function encoders.boolean(b)
	return tostring(b)
end

function encoders.table(t)
	if #t > 0 and next(t) == 1 then
		local objects = {}
		for _, v in ipairs(t) do
			objects[#objects + 1] = encode(v)
		end
		return string.format("[%s]",
			table.concat(objects, ","))
	else
		local objects = {}
		for k, v in pairs(t) do
			objects[#objects + 1] = string.format(
				"%s:%s", encode(k), encode(v))
		end
		return string.format("{%s}",
			table.concat(objects, ","))
	end
end

return { "JSON engine", encode = encode }
