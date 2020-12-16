---@type discordia
local discordia = require('discordia')

local stringx = discordia.extensions.string

---@type enums.argumentType
local argumentType = require('./enums').argumentType

local Context, get = discordia.class('Context')

local routes = require('./endpoints')

local f = string.format

--- Represents the "context" around a slash command event
---@class Context

--- Create a new context
---@param client Client
---@param data table
---@return Context
function Context:__init(client, data, arguments)
   self._client = client
   self._data = data
   self._arguments = arguments

   self._id = data.id
   self._token = data.token

   local guild = client:getGuild(data.guild_id)

   if not guild then
      return client:warn('Uncached Guild (' .. data.guild_id .. ') on INTERACTION_CREATE')
   end

   self._guild = guild

   self._member = guild:getMember(data.member.user.id)

   self._author = self._member.user

   self._channel = guild:getChannel(data.channel_id)

   -- We can't rely on the message coming in

   local mappedArguments = {}

   for _, v in pairs(arguments) do
      mappedArguments[v.name] = v
   end

   local parsed = {}

   for _, v in pairs(data.data.options) do
      local i = v.name
      v = stringx.trim(v.value)

      local argument = mappedArguments[i]

      -- oh god

      if argument.type == argumentType.boolean then
         parsed[i] = v
      elseif argument.type == argumentType.integer then
         parsed[i] = tonumber(v)
      elseif argument.type == argumentType.string then
         parsed[i] = v
      elseif argument.type == argumentType.user then
         parsed[i] = guild:getMember(v)
      elseif argument.type == argumentType.role then
         parsed[i] = guild:getRole(v)
      elseif argument.type == argumentType.channel then
         parsed[i] = guild:getChannel(v)
      end
   end

   self._arguments = parsed
end

function Context:reply(content, mode)
   local data = {}

   if type(content) == 'table' then
      data = content
   else
      data.content = content
   end

   return self._client._api:request('POST', f(routes.INTERACTION_CALLBACK, self._id, self._token), {
      data = data,
      type = mode or 4
   })
end

function Context:ack(mode)
   return self._client._api:request('POST', f(routes.INTERACTION_CALLBACK, self._id, self._token), {
      type = mode or 2
   })
end

function get:arguments()
   return self._arguments
end

function get:author()
   return self._author
end

function get:channel()
   return self._channel
end

function get:guild()
   return self._guild
end

function get:member()
   return self._member
end

return Context