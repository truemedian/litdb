local bestore = require './init'
--bestore:autoLoad(false)
bestore:autoSave(false)

bestore = bestore()
local store = bestore.store

-- p(store)

local slot = store:getStore 'slot'

-- p(slot)

 p(slot:set('KEY', 'value-long'))
-- p(slot:getHandle())

-- bestore.paths.handles:set 'bestori/_handles'

-- bestore = bestore()

-- local inspect = require 'inspect'
-- inspect.highPrint(bestore)

-- bestore {
--     handles = 'storage/hand'
-- }

-- for name, path in pairs(bestore.paths) do
--     if bestore.paths.isPath(path) then
--         p(name, path:get())
--     end
-- end

-- for n, v in pairs(bestore) do
--     p(n, v)
-- end

-- for n, v in bestore.holder() do
--     p(n ,v)
-- end

-- for i, v in bestore.paths.handles:iter() do
--     p(i,v)
-- end

--p(bestore.paths:getPathNames())