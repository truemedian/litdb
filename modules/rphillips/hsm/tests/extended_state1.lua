local exports = {}

local string = require('string')
local hsm = require('../hsm')
local StateMachine = hsm.StateMachine

exports['extended_state1'] = function (test)
  local FragileKeyboard = StateMachine:extend()

  function FragileKeyboard:initialize()
    self:defineStates{
      Default = {},
      CapsLocked = {},
      Final = {}
    }
    self.state = self.states.Default
    self.keyCount = 5
  end

  function FragileKeyboard:_reactDefault(keyName)
    if keyName == 'CAPS_LOCK' then
      return self.states.CapsLocked
    else
      self:_handleLowerCaseScanCode(keyName)
      return self.keyCount > 0 and self.states.Default or self.states.Final
    end
  end

  function FragileKeyboard:_reactCapsLocked(keyName)
    if keyName == 'CAPS_LOCK' then
      return self.states.Default
    else
      self:_handleUpperCaseScanCode(keyName)
      return self.keyCount > 0 and self.states.CapsLocked or self.states.Final
    end
  end

  function FragileKeyboard:_handleLowerCaseScanCode(keyName)
    self.output = string.lower(keyName)
    self.keyCount = self.keyCount - 1
  end

  function FragileKeyboard:_handleUpperCaseScanCode(keyName)
    self.output = string.upper(keyName)
    self.keyCount = self.keyCount - 1
  end

  local keyboard = FragileKeyboard:new()
  keyboard:react('a')
  test.equal(keyboard.output, 'a')
  keyboard:react('b')
  test.equal(keyboard.output, 'b')
  keyboard:react('CAPS_LOCK')
  keyboard:react('c')
  test.equal(keyboard.output, 'C')
  keyboard:react('d')
  test.equal(keyboard.output, 'D')
  keyboard:react('CAPS_LOCK')
  keyboard:react('e')
  test.equal(keyboard.output, 'e')
  test.ok(keyboard.state, keyboard.states.Final)
  test.done()
end

return exports
