--[[
Copyright 2021 Bilal2453. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]
--[[lit-meta
  name = "bilal2453/discordia-replies"
  version = "1.2.2"
  homepage = "https://github.com/bilal2453/discordia-replies/"
  description = "An addon for the library Discordia 2 to provide replies support."
  tags = {"discordia", "replies", "bots", "discord"}
  license = "Apache License 2.0"
]]

local readFileSync = require("fs").readFileSync
local splitPath = require("pathjoin").splitPath
local configs = {}
local discordia -- lazy required/provided by user

local function assertType(value, types, arg, name)
  value = type(value) == "table" and value.__name or type(value)
  name = name or '?'
  arg = arg or '?'
  local match
  for type in types:gmatch('(%w+)|?') do
    if type == value then match = true end
  end
  if not match then
    error(("bad argument #%s to '%s' (%s expected, got %s)"):format(arg, name, types, value))
  end
end

-- The following code have been copied from the original Discordia source code, and slightly modified,
-- aiming to replucate the same exact behavoir of the original send method, while supporting additional features,
-- without having to patch the original source code to do so.
-- All rights reserved for SinisterRectus and the contributers of SinisterRectus/discordia under the MIT license.
-- This do include changes made by the author of this module!

--[[ Start of Discordia copied code ]]

-- libs/containers/abstract/TextChannel.lua --

local function parseFile(obj, files)
	if type(obj) == "string" then
		local data, err = readFileSync(obj)
		if not data then return nil, err end
		files = files or {}
		table.insert(files, {table.remove(splitPath(obj)), data})
	elseif type(obj) == "table" and type(obj[1]) == "string" and type(obj[2]) == "string" then
		files = files or {}
		table.insert(files, obj)
	else
		return nil, "Invalid file object: " .. tostring(obj)
	end
	return files
end

local function parseMention(obj, mentions)
	if type(obj) == "table" and obj.mentionString then
		mentions = mentions or {}
		table.insert(mentions, obj.mentionString)
	else
		return nil, "Unmentionable object: " .. tostring(obj)
	end
	return mentions
end

local function send(self, content)
	local data, err

  if type(content) == "table" then
    local tbl = content
    content = tbl.content

    if type(tbl.code) == "string" then
      content = string.format("```%s\n%s\n```", tbl.code, content)
    elseif tbl.code == true then
      content = string.format("```\n%s\n```", content)
    end

    local mentions
    if tbl.mention then
      mentions, err = parseMention(tbl.mention)
      if err then return nil, err end
    end
    if type(tbl.mentions) == "table" then
      for _, mention in ipairs(tbl.mentions) do
        mentions, err = parseMention(mention, mentions)
        if err then return nil, err end
      end
    end

    if mentions then
      table.insert(mentions, content)
      content = table.concat(mentions, ' ')
    end

    local files
    if tbl.file then
      files, err = parseFile(tbl.file)
      if err then return nil, err end
    end
    if type(tbl.files) == "table" then
      for _, file in ipairs(tbl.files) do
        files, err = parseFile(file, files)
        if err then return nil, err end
      end
    end

    data, err = self.client._api:createMessage(self._id, {
      content = content,
      tts = tbl.tts,
      nonce = tbl.nonce,
      embed = tbl.embed,
      allowed_mentions = tbl.allowedMentions,
      message_reference = tbl.messageReference,
    }, files)
  else
    data, err = self.client._api:createMessage(self._id, {content = content})
  end

	if data then
		return self._messages:_insert(data)
	else
		return nil, err
	end
end

-- libs/containers/Message.lua --

local function parseMentions(content, pattern)
	if not content:find('%b<>') then return end
	local mentions, seen = {}, {}
	for id in content:gmatch(pattern) do
		if not seen[id] then
			table.insert(mentions, id)
			seen[id] = true
		end
	end
	return mentions
end

local function loadMore(self, data)
	if data.mentions then
		for _, user in ipairs(data.mentions) do
			if user.member then
				user.member.user = user
				self._parent._parent._members:_insert(user.member)
			else
				self.client._users:_insert(user)
			end
		end
	end

	local content = data.content
	if content then
		if self._mentioned_users then
			self._mentioned_users._array = parseMentions(content, '<@!?(%d+)>')
		end
		if self._mentioned_roles then
			self._mentioned_roles._array = parseMentions(content, '<@&(%d+)>')
		end
		if self._mentioned_channels then
			self._mentioned_channels._array = parseMentions(content, '<#(%d+)>')
		end
		if self._mentioned_emojis then
			self._mentioned_emojis._array = parseMentions(content, '<a?:[%w_]+:(%d+)>')
		end
		self._clean_content = nil
	end

	if data.embeds then
		self._embeds = #data.embeds > 0 and data.embeds or nil
	end

	if data.attachments then
		self._attachments = #data.attachments > 0 and data.attachments or nil
	end

  if data.message_reference then
    self._message_reference = data.message_reference
  end
  if data.referenced_message and next(data.referenced_message) then
    self._referenced_message = self._parent._messages:_insert(data.referenced_message)
  end
end

--[[ End of copied code ]]

local function reply(msg, content)
  assertType(msg, "Message", 1, "reply")
  assertType(content, "string|table", 2, "reply")

  -- Setting content
  if type(content) ~= "table" then
    content = {content = tostring(content)}
  end
  -- Setting allowed_mentions
  -- Discord treats mentions by content if no allowed_mention is passed, therefor no need to pass it when true
  if configs.replyMention == false and not content.allowedMentions then
    content.allowedMentions = {
      replied_user = false
    }
  end
  -- Setting message_reference
  content.messageReference = not content.messageReference and {
    message_id = msg.id,
    fail_if_not_exists = configs.failIfNotExists,
  }

  return send(msg.channel, content)
end

local function repliesTo(msg)
  if msg._repliesTo then return msg._repliesTo end -- is it cached already?
  if not msg._message_reference then return end -- any chance it's a reply?
  if not (msg.content or msg.attachment or msg.embeds) then return end -- is it really a reply message?
  -- Messages of type 21 also do have message_reference, can't check that since we are on API v7

  local client = msg.client
  local struct = {client = client}
  msg._repliesTo = struct

  -- Do we already have everything we need provided?
  local refMsg = msg._referenced_message
  if refMsg then
    struct.message = msg._referenced_message
    struct.channel = refMsg.channel
    struct.guild = refMsg.guild
    return struct
  end

  local ref = msg._message_reference
  local messageId, channelId = ref.message_id, ref.channel_id

  -- Get the Guild and TextChannel objects
  local guild, channel = client._channel_map[channelId]
  if guild then
    channel = guild._text_channels:get(channelId)
  else
    channel = client._private_channels:get(channelId) or client._group_channels:get(channelId)
  end
  struct.channel = channel
  struct.guild = guild

  if not channel then return struct end -- Not sure if possible but just in case

  -- Get the Message object
  struct.message = channel._messages:get(messageId) -- Try to fetch it from cache first
  if not struct.message and configs.fetchMessage then -- Not cached, fetch it from the API
    local data = client._api:getChannelMessage(channel._id, messageId)
    if data then struct.message = channel._messages:_insert(data) end
  end
  return struct
end

local function init(_, options)
  assertType(options, "table|nil", 1)
  -- is `options` the actual options table or is it the Discordia module?
  -- This is only here because I was (and probably still) dumb, it'd break backward compatibilty (ish) if removed
  if options then
      configs = options
      if (options.package or {}).name == "SinisterRectus/discordia" then
      discordia = options
      configs = {discordia = options}
    elseif options.discordia and (options.discordia.package or {}).name == "SinisterRectus/discordia" then
      discordia = options.discordia
    end
  end

  discordia = discordia or assert(require("discordia"), "This module requires Discordia to be installed!")
  local classes = discordia.class.classes

  -- Patch reply method in
  if configs.replaceOriginal then
    classes.Message.reply = reply
  else
    classes.Message[configs.replyIndex or "newReply"] = reply
  end

  -- Patch send method in, not recommended therefor disabled by default
  if configs.patchSend then
    local patchChannels = {"TextChannel", "GuildTextChannel", "PrivateChannel", "GroupChannel"}
    for i=1, #patchChannels do
      classes[patchChannels[i]][configs.sendIndex or "send"] = send
    end
  end

  -- Provide Message.repliesTo getter
  if configs.patchGetters or configs.patchGetters == nil then
    classes.Message._loadMore = loadMore -- needed to load _message_reference in
    classes.Message.__getters.repliesTo = repliesTo
  end

  -- Defaulting options
  configs.failIfNotExists = configs.failIfNotExists == false and false or nil -- Saving on payload size

  -- Returns the patched Discordia module, for convenience
  return discordia
end

return setmetatable({
  send = send,
  reply = reply,
  module = "Bilal2453/discordia-replies",
  version = '1.2.2',
}, {
  __call = init
})
