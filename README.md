lit-password-test
=================

Test a password for strength, length, and custom rules.

### Config Options

This is a copy of the default config.

```lua
local default_config = {
  ['allowPassphrases']       = true,
  ['maxLength']              = 128,
  ['minLength']              = 10,
  ['minPhraseLength']        = 20,
  ['minOptionalTestsToPass'] = 4
}
```

This is an example of an empty results table.

```lua
local result = {
  ['errors']              = {}, -- array of error messages
  ['failedTests']         = {}, -- array of failed tests
  ['passedTests']         = {}, -- array of passed tests
  ['isPassphrase']        = false, -- is this considered a passphrase?
  ['strong']              = true, -- is this a strong password?
  ['optionalTestsPassed'] = 0 -- number of optional tests passed
}
```

Here is each test number as a description for a failed test.

1. minimum length
2. maximum length
3. repeating characters
4. lowercase letter
5. uppercase letter
6. number
7. special character

Input:

```lua
local test = require('password-test')

p("weakpassword =", test("weakpassword"))
p("Stronger_passw0rd =", test("Stronger_passw0rd"))
p("My_pasw0rd! =", test("My_pasw0rd!"))
p("This-secret-is-strong-strong-str0ng! =", test("This-secret-is-strong-strong-str0ng!"))

local my_config = {
  ['minLength'] = 20
}

p("Min Length 20. Password = My_pasw0rd! =", test("My_pasw0rd!", my_config))
```

Output:

```
'weakpassword' = { optionalTestsPassed = 1,
  errors = {
    'The password may not contain sequences of three or more repeated characters.',
    'The password must contain at least one uppercase letter.',
    'The password must contain at least one number.',
    'The password must contain at least one special character.' },
  failedTests = { 3, 5, 6, 7 }, strong = false, isPassphrase = false,
  passedTests = { 1, 2, 4 } }

'Stronger_passw0rd' = { optionalTestsPassed = 4,
  errors = {
    'The password may not contain sequences of three or more repeated characters.' },
  failedTests = { 3 }, strong = false, isPassphrase = false,
  passedTests = { 1, 2, 4, 5, 6, 7 } }

'My_pasw0rd!' = { optionalTestsPassed = 4, errors = { }, failedTests = { }, strong = true,
  isPassphrase = false, passedTests = { 1, 2, 3, 4, 5, 6, 7 } }

'This-secret-is-strong-strong-str0ng!' = { optionalTestsPassed = 0, errors = { }, failedTests = { }, strong = false,
  isPassphrase = true, passedTests = { 1, 2, 3 } }

'Min Length 20. Password = My_pasw0rd!' = { optionalTestsPassed = 4,
  errors = { 'The password must be at least 20 characters long.' }, failedTests = { 1 },
  strong = false, isPassphrase = false, passedTests = { 2, 3, 4, 5, 6, 7 } }
```