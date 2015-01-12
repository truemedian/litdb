local exports = {}

local table = require('table')
local hsm = require('../hsm')
local HierarchicalStateMachine = hsm.HierarchicalStateMachine

exports['localTransition'] = function (test)
  local TestMachine = HierarchicalStateMachine:extend()
  
  function TestMachine:initialize()
    self:defineStates{
      S1 = {
        S2 = {}
      }
    }
    self.state = self.states.S1
  end

  function TestMachine:_entryS1()
    self:addLog('s1_entry')
  end
  function TestMachine:_reactS1(event)
    self:addLog('s1_react')
    return self.states.S2
  end
  function TestMachine:_exitS1()
    self:addLog('s1_exit')
  end

  function TestMachine:_entryS2()
    self:addLog('s2_entry')
  end
  function TestMachine:_reactS2(event)
    self:addLog('s2_react')
    return self.states.S1
  end
  function TestMachine:_exitS2()
    self:addLog('s2_exit')
  end

  function TestMachine:addLog(log)
    table.insert(self.log, log)
  end

  local machine = TestMachine:new()
  machine.log = {}
  machine:react()
  test.equal('s1_react,s2_entry', table.concat(machine.log, ','))

  machine.log = {}
  machine:react()
  test.equal('s2_react,s2_exit', table.concat(machine.log, ','))

  machine.log = {}
  machine:react()
  test.equal('s1_react,s2_entry', table.concat(machine.log, ','))

  test.done()
end

return exports
