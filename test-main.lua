local diceware = require('./init')

-- 6 words, this is default
print(diceware())

-- 3 words, words spaced with ' '
print(diceware(3, ' '))

-- 6 words, words spaced with '-'
print(diceware(nil, '-'))

-- 6 words, words spaced with '-', return a table
local t = diceware(6, '-', true)