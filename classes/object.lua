local Object = class()

function Object:__init(id, client)
    self.id = id
    self.client = client
end

return Object
