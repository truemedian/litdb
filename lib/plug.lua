-- MIT License
-- Copyright (c) 2019 Martin Aguilar

local JSON = require('json')
local f = require('./format')
local util = require('./util')
local p = require('./process')

-- Plug class

local Plug = function(filename, desc, config)

   local this = {
      config = config or {}
   }

   this.filename = filename

   -- Base class
   this.base_class = {
      ['//'] = {
         'Auto generated with <3 by Plug (mrtnpwn/plug).',
         'Compile date: ' .. os.date('%x %X')
      },
      foreign_ids = {},
      mod_desc = {
         filename = filename,
         author = this.config.author or nil,
         uuid = this.config.uuid or nil,
         version = this.config.version or nil
      }
   }

   this.desc = desc(f, p)

   -- Methods
   return {
      compose = function(model, keep_base)
         if not keep_base then keep_base = false end

         if model and keep_base == false then
            this.base_class = model.export()
         elseif model and keep_base == true then
            util.merge(this.base_class, model.export())
         end

         util.merge(this.base_class, this.desc)

         local plugin = io.open(this.filename .. '.json', 'w')

         plugin:write(JSON.encode(this.base_class))
         plugin:close()
      end
   }
end

return Plug
