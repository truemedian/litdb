-- Modified version of lume.format() from rxi/lume
-- to handle type's templates.

local process = function(str, vars, defaults, static)
   if not vars then
      error('Description expected, got nil.')
      return 1
   end

   local f = function(x)
      if vars[x] then
         if static and static[x] and type(vars[x]) ~= static[x] then
            error(x .. ' expected to be ' .. static[x] .. ', got ' .. type(vars[x]) .. '.')
            return tostring(vars[x])
         elseif static and type(vars[x]) == static[x] then
            return tostring(vars[x])
         else
            return tostring(vars[x])
         end
      else
         if defaults and defaults[x] and vars[x] == nil then
            return tostring(defaults[x])
         else
            return tostring(0)
         end
      end
   end

   return (str:gsub("<(.-)>", f))
end

return process
