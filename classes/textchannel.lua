local Deque = require('./deque')
local Object = require('./object')
local Server = require('./server')
local request = require('../utils').request
local endpoints = require('../endpoints')

local TextChannel = class(Object)

function TextChannel:__init(data, parent)

    Object.__init(self, data.id, parent.client or parent)

    self.isPrivate = data.isPrivate
    self.lastMessageId = data.lastMessageId

    self.messages = {}
    self.deque = Deque()

end

function TextChannel:sendMessage(content)
    local body = {content = content}
    request('POST', {endpoints.channels, self.id, 'messages'}, self.client.headers, body)
end

function TextChannel:getMessageHistory()
    return request('GET', {endpoints.channels, self.id, 'messages'})
end

function TextChannel:getMessageById(id)
    return self.messages[id]
end

return TextChannel
