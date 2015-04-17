local push = require('table').insert
local match = require('string').match

function password_test(password, config)

  local default_config = {
    ['allowPassphrases']       = true,
    ['maxLength']              = 128,
    ['minLength']              = 10,
    ['minPhraseLength']        = 20,
    ['minOptionalTestsToPass'] = 4
  }

  if config == nil then
    -- These are configuration settings that will be used when testing password strength
    config = default_config
  else
    for k,v in pairs(default_config) do
      if config[k] == nil then
        config[k] = v
      end
    end
  end

  local function findDuplicates(str)
    local previousLetter = ""
    local count = 0
    str:gsub(".", function(letter)
      if letter == previousLetter then
        count = count + 1
      else
        previousLetter = letter
      end
    end)
    return count
  end

  -- An array of required tests. A password *must* pass these tests in order to be considered strong.
  local required = {
    function(password)
      -- enforce a minimum length
      if (#password < config.minLength) then
        return 'The password must be at least ' .. config.minLength .. ' characters long.'
      end
    end,
    function(password)
      -- enforce a maximum length
      if (#password > config.maxLength) then
        return 'The password must be fewer than ' .. config.maxLength .. ' characters.'
      end
    end,
    function(password)
      -- forbid repeating characters
      if (findDuplicates(password) >= 1) then
        return 'The password may not contain sequences of three or more repeated characters.'
      end
    end
  }

  -- An array of optional tests. These tests are "optional" in two senses:
  -- 1. Passphrases (passwords whose length exceeds
  --    config.minPhraseLength) are not obligated to pass these tests
  --    provided that config.allowPassphrases is set to Boolean true
  --    (which it is by default).
  -- 2. A password need only to pass config.minOptionalTestsToPass
  --    number of these optional tests in order to be considered strong.
  local optional = {
    function(password)
      if (match(password, '[a-z]') == nil) then
        -- require at least one lowercase letter
        return 'The password must contain at least one lowercase letter.'
      end
    end,
    function(password)
      if (match(password, '%u') == nil) then
        -- require at least one uppercase letter
        return 'The password must contain at least one uppercase letter.'
      end
    end,
    function(password)
      if (match(password, '[0-9]') == nil) then
        -- require at least one number
        return 'The password must contain at least one number.'
      end
    end,
    function(password)
      if (match(password, '%W+') == nil) then
        -- require at least one special character
        return 'The password must contain at least one special character.'
      end
   end
  }

  -- This method tests password strength
  function test(password)

    -- create an object to store the test results
    local result = {
      ['errors']              = {},
      ['failedTests']         = {},
      ['passedTests']         = {},
      ['isPassphrase']        = false,
      ['strong']              = true,
      ['optionalTestsPassed'] = 0
    }

    -- Always submit the password/passphrase to the required tests
    for i = 1, #required do
      -- this.tests.required.forEach(function(test)
      local err = required[i](password)
      if (type(err) == 'string') then
        result.strong = false
        push(result.errors, err)
        push(result.failedTests, i)
      else
        push(result.passedTests, i)
      end
    end

    -- If configured to allow passphrases, and if the password is of a
    -- sufficient length to consider it a passphrase, exempt it from the
    -- optional tests.
    if ( config.allowPassphrases and #password >= config.minPhraseLength ) then
      result.isPassphrase = true
    end

    if (result.isPassphrase == false) then
      local j = #required
      for i = 1 , #optional do
        local err = optional[i](password)
        if (type(err) == 'string') then
          push(result.errors, err)
          push(result.failedTests, (i + j))
        else
          result.optionalTestsPassed = result.optionalTestsPassed + 1
          push(result.passedTests, (i + j))
        end
      end
    end

    -- If the password is not a passphrase, assert that it has passed a
    -- sufficient number of the optional tests, per the configuration
    if (result.isPassphrase and result.optionalTestsPassed < config.minOptionalTestsToPass) then
      result.strong = false
    end

    -- return the result
    return result
  end
  -- call the test function with the passed password
  return test(password)
end

return password_test