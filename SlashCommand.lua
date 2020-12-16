---@type discordia
local discordia = require('discordia')

local class = discordia.class

local routes = require('./endpoints')
local context = require('./Context')

local f = string.format

local function equals(o1, o2, ignore_mt)
   if o1 == o2 then return true end

   local o1Type = type(o1)
   local o2Type = type(o2)

   if o1Type ~= o2Type then return false end
   if o1Type ~= 'table' then return false end

   if not ignore_mt then
      local mt1 = getmetatable(o1)
      if mt1 and mt1.__eq then
         --compare using built in method
         return o1 == o2
      end
   end

   local keySet = {}

   for key1, value1 in pairs(o1) do
      local value2 = o2[key1]
      if value2 == nil or equals(value1, value2, ignore_mt) == false then
         return false
      end
      keySet[key1] = true
   end

   for key2, _ in pairs(o2) do
      if not keySet[key2] then
         return false
      end
   end
   return true
end


--- A slash command class to make slash commands
---@class SlashCommand
local SlashCommand = class('SlashCommand')

SlashCommand.globals = {}
SlashCommand.registered = {}

--- Create a new slash command, use `:commit` to push the changes
---@param client Client
function SlashCommand:__init(client, name, description)
   self._client = client
   self._name = name

   assert(
      #name >= 3 and #name <= 32,
      'Name must be at least 3 characters long and at most 32 characters long'
   )

   description = description or 'none'

   assert(
      #description >= 3 and #description <= 100,
      'Description must be at least 3 characters long and at most 100 characters long'
   )

   self._description = description

   ---@type Array
   self._options = {}
end

---@return Array
function SlashCommand:_fetch(guild)
   local id = self._client:getApplicationInformation().id

   self._id = id

   return self._client._api:request('GET', f(
      guild and routes.APPLICATION_GUILD_COMMANDS or
      routes.APPLICATION_COMMANDS, id, guild
   ))
end

--- Add an argument to the command
---@param name string
---@param desc string
---@param argType number
---@param other table
---@return SlashCommand
function SlashCommand:argument(name, desc, argType, other)
   local builder = {}

   other = other or {}

   assert(
      #name >= 3 and #name <= 32,
      'Name must be at least 3 characters long and at most 32 characters long'
   )

   builder.name = name

   assert(
      #desc >= 3 and #desc <= 100,
      'Description must be at least 3 characters long and at most 100 characters long'
   )

   builder.description = desc

   --; TODO subcommands
   assert(argType > 0 and argType < 9, 'Argument types must be between 1 and 9')

   builder.type = argType

   builder.default = other.default

   if builder.default then
      builder.required = false
   elseif other.required ~= false then
      builder.required = true
   else
      builder.required = false
   end

   if other.choices then
      builder.choices = {}

      for i, v in pairs(other.choices) do
         builder.choices = {
            name = i,
            value = v
         }
      end
   end

   table.insert(self._options, builder)

   return self
end

--- Add an execute function to the command
---@param cb fun(ctx: Context)
function SlashCommand:execute(cb)
   if not next(SlashCommand.registered) then
      function self._client._events.INTERACTION_CREATE(d)
         local cmd = SlashCommand.registered[d.data.name]

         if cmd then
            cmd._cb(context(cmd._client, d, cmd._options))
         else
            self._client:warning('Unhandled interaction `%s`', d.data.name)
         end
      end
   end

   self._cb = cb

   SlashCommand.registered[self._name] = self
end

--- Delete the slash commands
---
--- **This cannot be undone!**
---@param guild string The id of the guild to delete the command from
---@overload fun(): any, nil | string
function SlashCommand:delete(guild)
   local endpoint = guild and routes.APPLICATION_GUILD_COMMANDS or routes.APPLICATION_COMMANDS

   return self._client._api:request('DELETE', f(endpoint, self._id, guild))
end

--- Push the new command to the api
---@param guild string The id of the guild to push to
---@overload fun(): any, nil | string
---@return any, nil | string
function SlashCommand:commit(guild)
   local endpoint = guild and routes.APPLICATION_GUILD_COMMANDS or routes.APPLICATION_COMMANDS

   -- Use cached if it exists
   local data = guild and self:_fetch(guild) or
      next(SlashCommand.globals) and SlashCommand.globals or
      self:_fetch()

   local exists
   local same

   for i = 1, #data do
      if data[i].name == self._name then
         exists = true
         endpoint = endpoint .. '/' .. data[i].id -- Add needed part to edit

         data[i].id = nil
         data[i].application_id = nil

         same = equals(data[i], {
            name = self._name,
            description = self._description,
            options = self._options
         })

         break
      end
   end

   if not same then
      return self._client._api:request(exists and 'PATCH' or 'POST', f(endpoint, self._id, guild), {
         name = self._name,
         description = self._description,
         options = self._options
      })
   end
end

return SlashCommand