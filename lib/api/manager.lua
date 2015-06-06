-- -*- mode: lua; tab-width: 2; indent-tabs-mode: 0; st-rulers: [70] -*-
-- vim: ts=2 sw=2 ft=lua noet
----------------------------------------------------------------------
-- @author Daniel Barney <daniel@pagodabox.com>
-- @copyright 2015, Pagoda Box, Inc.
-- @doc
--
-- @end
-- Created :   15 May 2015 by Daniel Barney <daniel@pagodabox.com>
----------------------------------------------------------------------

local Cauterize = require('cauterize')
local Luvi = require('luvi')
local Api = Cauterize.Supervisor:extend()
local Splode = require('splode')
local splode = Splode.splode

local path = 'lib/api/routes'
function Api:_manage()
  local files = splode(Luvi.bundle.readdir,'no routes were present',
    path)
  for _,file in pairs(files) do
    local route = require('./routes/' .. file)


  end
end
return Api