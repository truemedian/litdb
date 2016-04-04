local TextChannel = require('./textchannel')
local ServerChannel = require('./serverchannel')

local ServerTextChannel = class(ServerChannel, TextChannel)

function ServerTextChannel:__init(data, server)

    ServerChannel.__init(self, data, server)
    TextChannel.__init(self, data, server)

end

return ServerTextChannel
