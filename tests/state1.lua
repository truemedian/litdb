local exports = {}

local string = require('string')
local hsm = require('../hsm')
local HierarchicalStateMachine = hsm.HierarchicalStateMachine

exports['isAncestorOf'] = function (test)
  local TestMachine = HierarchicalStateMachine:extend()
  
  function TestMachine:initialize()
    self:defineStates{
      A = {
        B = {
          C = {},
          D = {
            E = {}
          }
        }
      }
    }
  end

  local machine = TestMachine:new()
  local a = machine.states.A
  local d = machine.states.D
  local e = machine.states.E
  test.equal(machine:_isAncestorOf(e, nil), false)
  test.equal(machine:_isAncestorOf(e, e), true)
  test.equal(machine:_isAncestorOf(d, e), true)
  test.equal(machine:_isAncestorOf(a, e), true)
  test.equal(machine:_isAncestorOf(e, c), false)
  test.done()
end

exports['getLCA'] = function (test)
  local TestMachine = HierarchicalStateMachine:extend()
  
  function TestMachine:initialize()
    self:defineStates{
      A = {
        B = {
          C = {},
          D = {
            E = {}
          }
        }
      }
    }
  end

  local machine = TestMachine:new()
  local b = machine.states.B
  local c = machine.states.C
  local d = machine.states.D
  local e = machine.states.E
  test.equal(machine:_getLCA(e, nil), nil)
  test.equal(machine:_getLCA(e, d), d)
  test.equal(machine:_getLCA(d, e), d)
  test.equal(machine:_getLCA(e, c), b)
  test.done()
end

return exports
