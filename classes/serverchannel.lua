local Object = require('./object')
local request = require('../utils').request
local endpoints = require('../endpoints')

local ServerChannel = class(Object)

function ServerChannel:__init(data, server)

    Object.__init(self, data.id, server.client)

    self.type = data.type
    self.name = data.name
    self.topic = data.topic
    self.position = data.position
    self.permissionOverwrites = data.permissionOverwrites -- need to objectify

end

function ServerChannel:update(data)

    self.name = data.new
    self.topic = data.topic
    self.position = data.position
    self.permissionOverwrites = data.permissionOverwrites

end

function ServerChannel:delete(data)
    request('DELETE', {endpoints.channels, self.id}, self.client.headers)
end

return ServerChannel
