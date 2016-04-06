local User = require('./user')
local TextChannel = require('./textchannel')

class('PrivateChannel', TextChannel)

function PrivateChannel:initialize(data, client)

    TextChannel.initialize(self, data, client)

    local user = self.client:getUserById(self.id)
    if not user then
        user = User(data.recipient, self)
        self.client.users[user.id] = user
    else
        user:update(memberData, self)
    end
    self.recipient = user

end

return PrivateChannel
