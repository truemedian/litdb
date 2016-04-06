local TextChannel = require('./textchannel')
local ServerChannel = require('./serverchannel')

class('ServerTextChannel', ServerChannel, TextChannel)

function ServerTextChannel:initialize(data, server)

    ServerChannel.initialize(self, data, server)
    TextChannel.initialize(self, data, server)

end

return ServerTextChannel
