-- MIT License
-- Copyright (c) 2019 Martin Aguilar

local p = {}

function p.stop(reason)
   error(reason)
end

function p.trace(...)
   local deb = debug.getinfo(2, "Sl")
   local file = {
      src = deb.short_src
   }

   local msg = 'plug\t' .. file.src .. ':\t' .. tostring(...)
   print(msg)
end

return p
