
local require, assert = require, assert;

local uv = require('uv');
local json = require('json');

local data = assert(uv.fs_stat('./db.json'), 'mime-db failed to find db.json');
local fd = assert(uv.fs_open('./db.json', 'r', 444), 'mime-db failed to find db.json');
local body = assert(uv.fs_read(fd, data.size), 'mime-db failed to read db.json');

local body_json = json.decode(body);
local TAB = '\009';
local build = 'return {\n';

for mime_type, mime in next, body_json do
	build = build..TAB.."['"..mime_type.."'] = {\n";
	for field_name, field_value in next, mime do
		local t = type(field_value);
		local str = t == 'boolean' and (field_value == true and 'true' or field_value == false and 'false') or t == 'string' and "'"..field_value.."'";
		if (t == 'table') then
			str = '{';
			local n = #field_value;
			for i = 1, n do
				local v = field_value[i];
				str = str.."'"..v.."'"..(i < n and ', ' or '');
			end;
			str = str..'}';
		end;
		build = build..TAB..TAB..field_name..' = '..str..';\n';
	end;
	build = build..TAB..'};\n';
end;

build = build..'};\n';

local new_fd = assert(uv.fs_open('./db.lua', 'w', 777));
assert(uv.fs_write(new_fd, build, 0));
assert(uv.fs_close(new_fd));

assert(uv.fs_close(fd), 'mime-db failed to close db.json');

return body_json;