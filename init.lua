
local require, type = require, type;

local db = require('mime-db');
local extname = require('path').extname;

local NULL = '\0';
local TYPE_PATTERN = '[%a%-%+%.]*/[%a%-%+%.]*';
local TEXT_PATTERN = 'text/[%a%-%+%.]*';

local types, extensions = {}, {};
local t = {types = types; extensions = extensions;};

local valueAt = function(t, v)
	local n = #t;
	for i = 1, n do
		if (t[i] == v) then
			return i;
		end;
	end;
end;

t.charset = function(ctype) --working correctly
	if (type(ctype) == 'string') then
		ctype = ctype:lower();
		local s, f = ctype:find(TYPE_PATTERN);
		if (s and f) then
			ctype = ctype:sub(s, f);
		end;
		local mime = db[ctype];
		return mime and mime.charset or ctype:find(TEXT_PATTERN) ~= nil and 'UTF-8' or false;
	end;
	return false;
end;

t.extension = function(ctype) --working correctly
	if (type(ctype) == 'string') then
		ctype = ctype:lower();
		local s, f = ctype:find(TYPE_PATTERN);
		if (s and f) then
			ctype = ctype:sub(s, f);
		end;
		local ext = extensions[ctype];
		return ext and ext[1] or false;
	end;
	return false;
end;

t.contentType = function(str)
	if (type(str) == 'string') then
		local lstr = str:lower();
		local mime = lstr:find('/') == nil and t.lookup(lstr) or str;
		if (mime == str and not lstr:match(TYPE_PATTERN)) then
			return false;
		end;
		if not (mime:find('charset')) then
			local charset = t.charset(mime);
			if (charset) then
				mime = mime..'; charset='..charset:lower();
			end;
		end;
		return mime;
	end;
	return false;
end;

t.lookup = function(path)
	if (type(path) == 'string') then
		local extension = extname('x.'..path):sub(2);
		return extension and types[extension:lower()] or false;
	end;
	return false;
end;

t.charsets = {lookup = t.charset};

do
	local sources = {'nginx', 'apache', NULL, 'iana'};
	for mime_type, mime in next, db do
		local mime_extensions = mime.extensions;
		if (mime_extensions) then
			local n = #mime_extensions;
			--mime -> extensions
			extensions[mime_type] = mime_extensions;
			--extensions -> mime
			for i = 1, n do
				local extension = mime_extensions[i];
				local defined_mime_type = types[extension];
				local s = false;
				if (defined_mime_type) then
					local from = valueAt(sources, db[types[extension]].source or NULL);
					local to = valueAt(sources, mime.source or NULL);
					s = defined_mime_type ~= 'application/octet-stream' and (from > to or (from == to and defined_mime_type:sub(1, 12) == 'application/')) or false;
				end;
				if not (s) then
					types[extension] = mime_type;
				end;
			end;
		end;
	end;
end;

return t;
