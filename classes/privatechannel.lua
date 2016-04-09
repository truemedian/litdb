local User = require('./user')
local TextChannel = require('./textchannel')

class('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, client)
    TextChannel.__init(self, data, client)
    self.recipient = User(data.recipient, client)
    self.name = self.recipient.name
end

return PrivateChannel
