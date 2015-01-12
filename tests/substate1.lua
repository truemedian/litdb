local exports = {}

local string = require('string')
local table = require('table')
local hsm = require('../hsm')
local HierarchicalStateMachine = hsm.HierarchicalStateMachine

exports['substate1'] = function (test)
  local Calculator = HierarchicalStateMachine:extend()

  function Calculator:initialize()
    self:defineStates{
      On = {
        Operand1 = {},
        OpEntered = {},
        Operand2 = {},
        Result = {}
      },
      Final = {}
    }
    self.state = self.states.Operand1
  end

  (function()
    local keyMap = {
      off = 'Final'
    }
    function Calculator:_reactOn(keyName)
      return self.states[keyMap[keyName]]
    end
  end)();

  (function()
    local keyMap = {
      ['+'] = 'OpEntered',
      ['-'] = 'OpEntered',
      ['*'] = 'OpEntered',
      ['/'] = 'OpEntered'
    }
    function Calculator:_reactOperand1(keyName)
      return self.states[keyMap[keyName]]
    end
  end)();

  (function()
    local keyMap = {
      ['0'] = 'Operand2',
      ['1'] = 'Operand2',
      ['2'] = 'Operand2',
      ['3'] = 'Operand2',
      ['4'] = 'Operand2',
      ['5'] = 'Operand2',
      ['6'] = 'Operand2',
      ['7'] = 'Operand2',
      ['8'] = 'Operand2',
      ['9'] = 'Operand2',
      ['.'] = 'Operand2'
    }
    function Calculator:_reactOpEntered(keyName)
      return self.states[keyMap[keyName]]
    end
  end)();

  (function()
    local keyMap = {
      ['-'] = 'Result'
    }
    function Calculator:_reactOperand2(keyName)
      return self.states[keyMap[keyName]]
    end
  end)();

  (function()
    local keyMap = {
      ['0'] = 'Operand1',
      ['1'] = 'Operand1',
      ['2'] = 'Operand1',
      ['3'] = 'Operand1',
      ['4'] = 'Operand1',
      ['5'] = 'Operand1',
      ['6'] = 'Operand1',
      ['7'] = 'Operand1',
      ['8'] = 'Operand1',
      ['9'] = 'Operand1',
      ['.'] = 'Operand1',
      ['+'] = 'OpEntered',
      ['-'] = 'OpEntered',
      ['*'] = 'OpEntered',
      ['/'] = 'OpEntered'
    }
    function Calculator:_reactResult(keyName)
      return self.states[keyMap[keyName]]
    end
  end)();

  function Calculator:_exitOn()
    table.insert(self.log, 'On:exit')
  end

  function Calculator:_exitOperand1()
    table.insert(self.log, 'Operand1:exit')
  end

  function Calculator:_entryOpEntered()
    table.insert(self.log, 'OpEntered:entry')
  end

  function Calculator:_exitOpEntered()
    table.insert(self.log, 'OpEntered:exit')
  end

  function Calculator:_entryFinal()
    table.insert(self.log, 'Final:entry')
  end

  local calculator = Calculator:new()
  calculator.log = {}
  calculator:react('+')
  test.equal('Operand1:exit,OpEntered:entry',
    table.concat(calculator.log, ','))
  test.ok(calculator.state, calculator.states.OpEntered)
  calculator.log = {}
  calculator:react('off')
  test.ok(calculator.state, calculator.states.Final)
  test.equal('OpEntered:exit,On:exit,Final:entry',
    table.concat(calculator.log, ','))
  test.done()
end

return exports
