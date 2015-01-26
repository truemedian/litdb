local exports = {}

local table = require('table')
local hsm = require('../hsm')
local StateMachine = hsm.StateMachine

exports['initial'] = function (test)
  local Door = StateMachine:extend()

  function Door:initialize()
    self:defineStates{
      Initial = {},
      Open = {},
      Closed = {}
    }
    self.state = self.states.Initial
  end

  function Door:_reactInitial(event)
    if event == 'create' then
      self:addLog('initial')
      return self.states.Open
    else
      return nil
    end
  end

  function Door:_reactOpen(event)
    if event == 'close' then
      self:addLog('open_react')
      return self.states.Closed
    else
      return nil
    end
  end

  function Door:_reactClosed(event)
    if event == 'open' then
      self:addLog('closed_react')
      return self.states.Open
    else
      return nil
    end
  end

  function Door:_entryOpen()
    self:addLog('open_entry')
  end

  function Door:_exitOpen()
    self:addLog('open_exit')
  end

  function Door:_entryClosed()
    self:addLog('closed_entry')
  end

  function Door:_exitClosed()
    self:addLog('closed_exit')
  end

  function Door:addLog(log)
    table.insert(self.log, log)
  end

  local door = Door:new()
  door.log = {}
  door:react('create')
  test.equal('initial,open_entry', table.concat(door.log, ','))

  door.log = {}
  door:react('close')
  test.equal('open_react,open_exit,closed_entry', table.concat(door.log, ','))

  test.done()
end

return exports
