-- https://github.com/jatenate/diceware
local wordlist = require('./wordlist')
local join = require('table').concat
local random = require('math').random

-- http://arstechnica.com/information-technology/2014/03/diceware-passwords-now-need-six-random-words-to-thwart-hackers/
local DEFAULT_NUMWORDS = 6
-- local WORDLIST_SIZE = 7776 -- 6^5

function dicewords(numwords, spacer, table)
	if numwords == nil then
		numwords = DEFAULT_NUMWORDS
	end

	if spacer == nil then
		spacer = ""
	end

	local phrase = {}

	for i = 1, numwords do
		local dice = ""
		-- 5 dice rolled
		for _i = 1, 5 do
			-- use 6 sided dice
			dice = dice .. random(1, 6)
		end
		-- return a table?
		if table == nil then
			phrase[i] = wordlist[dice]
		else
			phrase[dice] = wordlist[dice]
		end
	end

	if table == nil then
		-- join the table using the spacer
		return join(phrase, spacer)
	else
		return phrase
	end
end

return dicewords