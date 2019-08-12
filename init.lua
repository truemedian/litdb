--[[lit-meta
   name = "lowscript-lang/lsvm"
   version = "0.1.0"
   dependencies = {}
   description = "Virtual Machine for the LowScript programming language."
   tags = { "vm", "moonscript" }
   license = "MIT"
   author = { name = "Martín Aguilar", email = "ik7swordking@gmail.com" }
   homepage = "https://github.com/lowscript-lang/lsvm"
]]

local vm = require("core").Object:extend()

local keywords = {
   ["declare"] = true,
   ["load"] = true,
   ["set"] = true,
   ["echo"] = true,
   ["use"] = true
}

local function diff(str1,str2)
   for i = 1,#str1 do --Loop over strings
       if str1:sub(i,i) ~= str2:sub(i,i) then --If that character is not equal to it's counterpart
           return i --Return that index
       end
   end
   return #str1+1 --Return the index after where the shorter one ends as fallback.
end

local function split(s, delimiter)
   local result = {}

   for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
      table.insert(result, match)
   end

   return result
end

local function exists(path)
   if io.open(path, "r") then
      return true
   end

   return false
end

local function read(path)
   if exists(path) then
      return io.open(path, "r"):read("*a")
   end

   return nil
end

local function determine_type(t)
   local tstring = t:gsub('"(.-)"', "%1")

   return tstring
end

-- Class

function vm:initialize()
   self.env = {
      pointer = 0
   }
end

local function get_probably(env, argument)
   local probably

   for k, v in pairs(env) do
      local something = diff(k, argument)

      print(something, #argument)

      if something >= #argument then
         probably = k
      end
   end

   return probably
end

function vm:run(command, argument)
   if command == "declare" then
      if self.env[argument] then
         error("error@vm: can't redeclare variable \"".. argument .. "\"")
      end

      self.env[argument] = argument

      return true
   end

   if command == "load" then
      if self.env[argument] == nil then
         local probably = get_probably(self.env, argument)

         error("error@vm: can't load cell \"".. argument .. "\"" .. "\n  suggestion: is it " .. probably .. "?")
      end

      self.env.pointer = self.env[argument]

      return true
   end

   if command == "set" then
      if self.env[self.env.pointer] ~= self.env.pointer then
         error("error@vm: can't set value to existing cell \"".. self.env.pointer .. "\"")
      end

      self.env[self.env.pointer] = determine_type(argument)

      if self.env[0] ~= nil then
         error("error@vm: out of memory")
      end

      return true
   end

   if command == "clear" then
      if self.env[argument] == nil then
         local probably = get_probably(self.env, argument)

         error("error@vm: can't clear nil cell \"".. argument .. "\"" .. "\n  suggestion: is it " .. probably .. "?")
      end

      self.env[argument] = 0

      return true
   end

   if command == "echo" then
      if self.env[argument] == nil then
         local probably = get_probably(self.env, argument)

         error("error@vm: can't print nil cell \"".. argument .. "\"" .. "\n  suggestion: is it " .. probably .. "?")
      end

      print(self.env[argument])

      return true
   end

   if command == "use" then
      local lib = read(argument .. ".lbin")

      local instance = vm:new()

      if lib == nil then
         error("error@vm: " .. argument .. " is not a valid script.")
      end

      for number, line in pairs(split(lib, "\n")) do
         local expression = split(line, " ")

         local _command = expression[1]

         table.remove(expression, 1)

         for k, v in pairs(expression) do
            if v == "" then
               expression[k] = nil
            end
         end

         if _command ~= "" then
            xpcall(function()
               instance:run(_command, table.concat(expression, " "))
            end, function(err)
               print("[" .. argument .. ".lbin" .. ": from line " .. number .. "] " .. err)
               print("\t" .. line)
               print("\t" .. string.rep("^", #line))
               os.exit(1)
            end)
         end
      end

      for k, v in pairs(instance.env) do
         if k ~= "pointer" then
            self.env[argument .. "." .. k] = v
         end
      end

      return true
   end

   if command == nil then
      return true
   end

   if keywords[command] == nil then
      error("error@vm: " .. command .. " is not a valid command")
   end
end

return vm
