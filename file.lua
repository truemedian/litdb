--[[lit-meta
	name = "alphafantomu/array-flatten"
    version = "0.0.2"
    description = "flatten nested arrays in lua"
    tags = { "lua", "array", "utility" }
    license = "MIT"
    author = { name = "Ari Kumikaeru"}
    homepage = "https://github.com/alphafantomu/array-flatten"
    files = {"**.lua"}
]]

local type = type;
local setNshiftUp, flattenArray;

local arrayAppend = function(array_a, array_b, si)
	local n = #array_b;
	for i = 0, n - 1 do
		local ni = si + i;
		local cv = array_a[ni];
		if (cv ~= nil) then
			setNshiftUp(array_a, ni + 1, cv);
		end;
		array_a[ni] = array_b[i + 1];
	end;
	return n - 1;
end;

flattenArray = function(array)
	local n = #array;
	local offset = 0;
	for i = 1, n do
		i = i + offset;
		local v = array[i];
		if (type(v) == 'table') then
			array[i], v = nil, flattenArray(v);
			offset = offset + arrayAppend(array, v, i);
		end;
	end;
	return array;
end;

setNshiftUp = function(array_a, i, v)
	local cv = array_a[i];
	if (cv ~= nil) then
		setNshiftUp(array_a, i + 1, cv);
	end;
	array_a[i] = v;
end;

return flattenArray;