-- This Script is Part of the cyber Obfuscator by DailyBGL#5936
--
-- test.lua
-- This script contains the Code for the cyber CLI

-- Configure package.path for requiring cyber
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*[/%\\])") or "";
end
package.path = script_path() .. "?.lua;" .. package.path;
require("src.cli");