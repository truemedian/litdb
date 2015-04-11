Diceware
========

A lit package that returns words and tables of passphases using the [Diceware method](https://firstlook.org/theintercept/2015/03/26/passphrases-can-memorize-attackers-cant-guess/). This was modified from the node.js version by [jatenate/diceware](https://github.com/jatenate/diceware).

### Install

```sh
$ lit install james2doyle/diceware
```

### Usage

Input:

```lua
local diceware = require('diceware')

-- 6 words, this is default
print(diceware())

-- 3 words, words spaced with ' '
print(diceware(3, ' '))

-- 6 words, words spaced with '-'
print(diceware(6, '-'))

-- 2 words, words spaced with '-', return a table
local t = diceware(6, '-', true)
```

Output:

```
cetuscoorsljessenoperarock
alto perch oe
lamb-lund-filch-kane-wheat-uuu
local t = { ['46245'] = 'pork', ['53663'] = 'sibley', ['44215'] = 'oboe',
  ['44566'] = 'ozone', ['61161'] = 'throes', ['16654'] = 'claus' }
```
