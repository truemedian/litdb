
local require, type = require, type;

local db = require('mime-db');
local extname = require('path').extname;

local NULL = '\0';
local TYPE_PATTERN = '[%a%-%+%.]*/[%a%-%+%.]*';
local TEXT_PATTERN = 'text/[%a%-%+%.]*';

local types, extensions = {}, {};
local t = {types = types; extensions = extensions;};

--[[
local getMimeType = function(str) --deprecated
	local PARTIAL_TYPE_PATTERN = '(%a*)/';
	local FULL_TYPE_PATTERN_NO_PUNC = PARTIAL_TYPE_PATTERN..'(%a*)';
	local media_s, media_f = str:find(PARTIAL_TYPE_PATTERN);
	if (media_s and media_f) then
		local s, f;
		local strange_start = str:find('-', media_f, true) or str:find('+', media_f, true) or str:find('.', media_f, true) or nil;
		if (strange_start) then --confirmed puncuation in extension
			local header_start = str:find(';');
			if (header_start and strange_start < header_start) then --need to confirm this is before the header attributes
				--should consider trimming the string as well?
				return str:sub(media_s, header_start):match('^%s*(.-)%s*$');
			else --not before header attributes, maybe the characters are in the attributes of the header?
				--act as if there is no puncuation
				s, f = str:find(FULL_TYPE_PATTERN_NO_PUNC);
			end;
		else s, f = str:find(FULL_TYPE_PATTERN_NO_PUNC);  --there is no puncuation
		end;
		if (s and f) then
			return str:sub(s, f);
		end;
	end;
end;

local getLastExtension = function(str)
	local EXT_PATTERN = '(%.)[%a%-%+%.]*';
	local length = str:len();
	local rev_str = str:reverse();
	local from_end = rev_str:find('%.');
	if (from_end) then
		local s, f = str:find(EXT_PATTERN, length - from_end - 1);
		if (s and f) then
			return str:sub(s, f);
		end;
	end;
	return false;
end;]]

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
		--get mimetype like text/html using the extension
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

--[[
do
	local mime = t;

	p(mime.lookup('json'),
	mime.lookup('.md'),
	mime.lookup('file.html'),
	mime.lookup('folder/file.js'),
	mime.lookup('folder/.htaccess'),

	mime.lookup('cats'));

	p(mime.contentType('markdown'),
	mime.contentType('file.json'),
	mime.contentType('text/html'),
	mime.contentType('text/html; charset=iso-8859-1'),
	mime.contentType(extname('/path/to/file.json')));

	p(mime.extension('application/octet-stream'));

	p(mime.charset('text/markdown'));

	print('-------------------');

	local mimeTypes = t;

	p('mimeTypes');
	p('.charset(type)');
	if not (mimeTypes.charset('application/json') == 'UTF-8') then
		p('should return "UTF-8" for "application/json"');
	end;
	if not (mimeTypes.charset('application/json; foo=bar') == 'UTF-8') then
		p('should return "UTF-8" for "application/json; foo=bar"');
	end;
	if not (mimeTypes.charset('application/javascript') == 'UTF-8') then
		p('should return "UTF-8" for "application/javascript"');
	end;
	if not (mimeTypes.charset('application/JavaScript') == 'UTF-8') then
		p('should return "UTF-8" for "application/JavaScript"');
	end;
	if not (mimeTypes.charset('text/html') == 'UTF-8') then
		p('should return "UTF-8" for "text/html"');
	end;
	if not (mimeTypes.charset('TEXT/HTML') == 'UTF-8') then
		p('should return "UTF-8" for "TEXT/HTML"');
	end;
	if not (mimeTypes.charset('text/x-bogus') == 'UTF-8') then
		p('should return "UTF-8" for any text/*');
	end;
	if not (mimeTypes.charset('application/x-bogus') == false) then
		p('should return false for unknown types');
	end;
	if not (mimeTypes.charset('application/octet-stream') == false) then
		p('should return false for any application/octet-stream');
	end;
	if not (mimeTypes.charset({}) == false and
			mimeTypes.charset(nil) == false and
			mimeTypes.charset(true) == false and
			mimeTypes.charset(42) == false) then
		p('should return false for invalid arguments');
	end;

	p('.contentType(extension)');
	if not (mimeTypes.contentType('html') == 'text/html; charset=utf-8') then
		p('should return content-type for "html"');
	end;
	if not (mimeTypes.contentType('.html') == 'text/html; charset=utf-8') then
		p('should return content-type for ".html"');
	end;
	if not (mimeTypes.contentType('jade') == 'text/jade; charset=utf-8') then
		p('should return content-type for "jade"');
	end;
	if not (mimeTypes.contentType('json') == 'application/json; charset=utf-8') then
		p('should return content-type for "json"');
	end;
	if not (mimeTypes.contentType('bogus') == false) then
		p('should return false for unknown extensions');
	end;
	if not (mimeTypes.contentType({}) == false and
			mimeTypes.contentType(nil) == false and
			mimeTypes.contentType(true) == false and
			mimeTypes.contentType(42) == false) then
		p('should return false for invalid arguments');
	end;

	p('.contentType(type)');
	if not (mimeTypes.contentType('application/json') == 'application/json; charset=utf-8') then
		p('should attach charset to "application/json"');
	end;
	if not (mimeTypes.contentType('application/json; foo=bar') == 'application/json; foo=bar; charset=utf-8') then
		p('should attach charset to "application/json; foo=bar"');
	end;
	if not (mimeTypes.contentType('TEXT/HTML') == 'TEXT/HTML; charset=utf-8') then
		p('should attach charset to "TEXT/HTML"');
	end;
	if not (mimeTypes.contentType('text/html') == 'text/html; charset=utf-8') then
		p('should attach charset to "text/html"');
	end;
	if not (mimeTypes.contentType('text/html; charset=iso-8859-1') == 'text/html; charset=iso-8859-1') then
		p('should not alter "text/html; charset=iso-8859-1"');
	end;
	if not (mimeTypes.contentType('application/x-bogus') == 'application/x-bogus') then
		p('should return type for unknown types');
	end;

	p('.extension(type)');
	if not (mimeTypes.extension('text/html') == 'html' and
			mimeTypes.extension(' text/html') == 'html' and
			mimeTypes.extension('text/html ') == 'html') then
		p('should return extension for mime type');
	end;
	if not (mimeTypes.extension('application/x-bogus') == false) then
		p('should return false for unknown type');
	end;
	if not (mimeTypes.extension('bogus') == false) then
		p('should return false for non-type string');
	end;
	if not (mimeTypes.extension(nil) == false and
			mimeTypes.extension(42) == false and
			mimeTypes.extension({}) == false) then
		p('should return false for non-strings');
	end;
	if not (mimeTypes.extension('text/html;charset=UTF-8') == 'html' and
			mimeTypes.extension('text/HTML; charset=UTF-8') == 'html' and
			mimeTypes.extension('text/html; charset=UTF-8') == 'html' and
			mimeTypes.extension('text/html; charset=UTF-8 ') == 'html' and
			mimeTypes.extension('text/html ; charset=UTF-8') == 'html') then
		p('should return extension for mime type with parameters');
	end;
	
	p('.lookup(extension)');
	if not (mimeTypes.lookup('.html') == 'text/html') then
		p('should return mime type for ".html"');
	end;
	if not (mimeTypes.lookup('.js') == 'application/javascript') then
		p('should return mime type for ".js"');
	end;
	if not (mimeTypes.lookup('.json') == 'application/json') then
		p('should return mime type for ".json"');
	end;
	if not (mimeTypes.lookup('.rtf') == 'application/rtf') then
		p('should return mime type for ".rtf"');
	end;
	if not (mimeTypes.lookup('.txt') == 'text/plain') then
		p('should return mime type for ".txt"');
	end;
	if not (mimeTypes.lookup('.xml') == 'application/xml') then
		p('should return mime type for ".xml"');
	end;
	if not (mimeTypes.lookup('html') == 'text/html' and
			mimeTypes.lookup('xml') == 'application/xml') then
		p('should work without the leading dot');
	end;
	if not (mimeTypes.lookup('HTML') == 'text/html' and
			mimeTypes.lookup('.Xml') == 'application/xml') then
		p('should be case insensitive');
	end;
	if not (mimeTypes.lookup('.bogus') == false and
			mimeTypes.lookup('bogus') == false) then
		p('should return false for unknown extension');
	end;
	if not (mimeTypes.lookup(nil) == false and
			mimeTypes.lookup(42) == false and
			mimeTypes.lookup({}) == false) then
		p('should return false for non-strings');
	end;
	
	p('.lookup(path)');
	if not (mimeTypes.lookup('page.html') == 'text/html') then
		p('should return mime type for file name');
	end;
	if not (mimeTypes.lookup('path/to/page.html') == 'text/html' and
			mimeTypes.lookup('path\\to\\page.html') == 'text/html') then
		p('should return mime type for relative path');
	end;
	if not (mimeTypes.lookup('/path/to/page.html') == 'text/html' and
			mimeTypes.lookup('C:\\path\\to\\page.html') == 'text/html') then
		p('should return mime type for absolute path');
	end;
	if not (mimeTypes.lookup('/path/to/PAGE.HTML') == 'text/html' and
			mimeTypes.lookup('C:\\path\\to\\PAGE.HTML') == 'text/html') then
		p('should be case insensitive');
	end;
	if not (mimeTypes.lookup('/path/to/file.bogus') == false) then
		p('should return false for unknown extension');
	end;
	if not (mimeTypes.lookup('/path/to/json') == false) then
		p('should return false for path without extension');
	end;

	p('-> path with dotfile');
	if not (mimeTypes.lookup('/path/to/.json') == false) then
		p('should return false when extension-less');
	end;
	if not (mimeTypes.lookup('/path/to/.config.json') == 'application/json') then
		p('should return mime type when there is extension');
	end;
	if not (mimeTypes.lookup('.config.json') == 'application/json') then
		p('should return mime type when there is extension, but no path');
	end;
end;]]

return t;
