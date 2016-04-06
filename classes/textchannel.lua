local Deque = require('./deque')
local Object = require('./object')
local Server = require('./server')
local Message = require('./message')
local request = require('../utils').request
local endpoints = require('../endpoints')

class('TextChannel', Object)

function TextChannel:initialize(data, parent)

    Object.initialize(self, data.id, parent.client or parent)

    self.isPrivate = data.isPrivate
    self.lastMessageId = data.lastMessageId

    self.messages = {}
    self.deque = Deque()

end

function TextChannel:createMessage(content)
    local body = {content = content}
    local data = request('POST', {endpoints.channels, self.id, 'messages'}, self.client.headers, body)
    return Message(data, self) -- not the same object that is cached
end

function TextChannel:sendMessage(content) -- alias for createMessage
    return self:createMessage(content)
end

function TextChannel:getMessageHistory()
    return request('GET', {endpoints.channels, self.id, 'messages'})
end

function TextChannel:getMessageById(id)
    return self.messages[id]
end

return TextChannel
