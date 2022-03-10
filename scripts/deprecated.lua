
local getMimeType = function(str)
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
end;