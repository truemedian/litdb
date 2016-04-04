local User = require('./user')
local TextChannel = require('./textchannel')

local PrivateChannel = class(TextChannel)

function PrivateChannel:__init(data, server)

    TextChannel.__init(self, data, server)

    self.server = server

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
