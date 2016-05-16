local classes = require('../classes')
local class = classes.new
local base = require('./base')

local api = require('../client/api')

local Server = class(base)

function Server:__constructor ()
	self.roles = classes.Cache()
	self.members = classes.Cache()
	self.channels = classes.Cache()
end

function Server:onUpdate ()
	self.owner = self.parent.users:get('id', self.owner_id)
	self.afk_channel = self.parent.channels:get('id', self.afk_channel_id)
	self.embed_channel = self.parent.channels:get('id', self.embed_channel_id)
end

function Server:createChannel (settings)
	api.request(
		{
			type = 'POST',
			path = 'guilds/'..self.id..'/channels',
			token = self.parent.socket.token,
			data = settings,
		}
	)
end
function Server:createTextChannel (name)
	self:createChannel(
		{
			type = 'text',
			name = name,
		}
	)
end
function Server:createVoiceChannel (name, bitrate)
	self:createChannel(
		{
			type = 'voice',
			name = name,
			bitrate = bitrate or 96000,
		}
	)
end

function Server:delete ()
	local success = api.request(
		{
			type = 'DELETE',
			path = 'guilds/'..self.id,
			token = self.parent.socket.token,
		}
	)
	if not success then return end
	self.parent.servers:remove(self)
end

function Server:modify (settings)
	api.request(
		{
			type = 'PATCH',
			path = 'guilds/'..self.id,
			token = self.parent.socket.token,
			data = settings,
		}
	)
end
function Server:setName (name)
	self:modify({name = name})
end
function Server:setRegion (region)
	self:modify({region = region})
end
function Server:setIcon (icon)
	self:modify({icon = icon})
end
function Server:setAFKchannel (channel)
	local id = channel
	if type(channel) == 'table' then
		id = channel.id
	end
	self:modify({channel = id})
end
function Server:setAFKtimeout (timeout)
	self:modify({afk_timeout = timeout})
end
function Server:setOwner (owner)
	local id = owner
	if type(owner) == 'table' then
		id = owner.id
	end
	self:modify({owner = id})
end
function Server:setSplash (splash)
	self:modify({splash = splash})
end

return Server