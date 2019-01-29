local class = require('./class')
local JSON = require('json')
local lume = require('./lume')

local local_config = {}

-- In-class functions
local f = {
   color = {
      green = function(...)
         return string.format('%s' .. ..., '#G')
      end,
      red = function(...)
         return string.format('%s' .. ..., '#R')
      end,
      blue = function(...)
         return string.format('%s' .. ..., '#B')
      end,
      hex = function(hc, ...)
         return string.format('%s' .. ..., '#c' .. hc)
      end
   },
   effect = {
      blink = function(...)
         return string.format('%s' .. ..., '#b')
      end
   },
   format = {
      tab = function(...)
         return string.format('%s' .. ..., '#P')
      end
   }
}

-- Plug class

local Plug = class(function(this, filename, desc)
   -- Filename for `compose` method.
   this.filename = filename

   -- Base class
   this.base_class = {
      comment = {
         'Auto generated with <3 by Plug (mrtnpwn/plug).',
         'Compile date: ' .. os.date('%x %X')
      },
      foreign_ids = {},
      mod_desc = {
         filename = filename,
         author = local_config.__author,
         uuid = local_config.__uuid,
         version = local_config.__version
      }
   }

   -- Declaring to call and get any errors here + use it on `compose` method.
   this.desc = desc(f)
end)

-- Static Functions

function Plug.setAuthor(uin)
   if uin then
      local_config.__author = uin
   end

   return uin or nil
end

function Plug.setVersion(version)
   if version then
      local_config.__version = version
   end

   return version or nil
end

function Plug.setUUID(uuid)
   if uuid then
      local_config.__uuid = uuid
   end

   return uuid or nil
end

-- Plug methods

function Plug:compose(category)
   if category == 'horse' then
      self.base_class = {
         comment = {
            'Auto generated with <3 by Plug (mrtnpwn/plug).',
            'Compile date: ' .. os.date('%x %X')
         },
      }
   end

   local desc = lume.extend(self.base_class, self.desc)
   local plugin = io.open(self.filename .. '.json', 'w')

   plugin:write(JSON.encode(desc))
   plugin:close()
end

return {
   Plug = Plug,
   UUID = require('luv4').gen
}
