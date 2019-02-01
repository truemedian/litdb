-- MIT License
-- Copyright (c) 2019 Martin Aguilar

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

return f
