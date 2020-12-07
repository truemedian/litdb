local function check()
   p(debug.getinfo(2))

   local func = debug.getinfo(2).func

   local params = {}

   local i = 1

   while true do
      local name = debug.getlocal(func, i)

      if name then
         params[name] = true

         i = i + 1
      else
         break
      end
   end

   i = 1

   local passed = {}

   while true do
      local name, val = debug.getlocal(2, i)

      if name then
         if params[name] then
            passed[name] = val
         end

         i = i + 1
      else
         break
      end
   end

   p(passed)

   return passed
end

local function hi(name)
   check()
end

hi('bob')