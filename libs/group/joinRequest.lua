local DateTime = require("util/datetime")

--[=[
    @within JoinRequest
    @prop Client Client
    @readonly
    A reference back to the client that owns this object.
]=]
--[=[
    @within JoinRequest
    @prop Requester User
    @readonly
    The user that made the request.
]=]
--[=[
    @within JoinRequest
    @prop Created number
    @readonly
    When the join request was made (unix time).
]=]
--[=[
    This object represents a group join request.

    @class JoinRequest
]=]
local JoinRequest = {}

--[=[
    Constructs a JoinRequest object, returns nil if there is no join request by that user
    for the group.

    @param _ JoinRequest
    @param Client Client -- The client to make requests with.
    @param GroupId Group|number -- The Group or GroupId the join request is for.
    @param UserId User|number -- The User or UserId that made the join request.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return JoinRequest?
]=]
function JoinRequest.__call (_,Client,GroupId,UserId,Data)
    local self = {}
    setmetatable(self,{__index=JoinRequest})

    self.Client = Client
    
    if type(GroupId) == "number" then
        self.Group = Client:Group (GroupId)
    elseif type(GroupId) == "table" then
        self.Group = GroupId
    else
        error ("Lublox: Invalid type for group!")
    end

    if type(UserId) == "number" or type(UserId) == "string" then
        self.User = Client:User (UserId)
    elseif type(UserId) == "table" then
        self.User = UserId 
    else
        error ("Lublox: Invalid type for user!")
    end

    if type(Data) == "table" then
        for i,v in pairs(Data) do
            self[i] = v
        end
    end

    if self.Valid then return self end

    local Success,Body = Client:Request ("GET","https://groups.roblox.com/v1/groups/"..self.Group.Id.."/join-requests/users/"..self.User.Id)
    if Success then
        if Body ~= nil then
            self.Created = DateTime(Body.created)
            return self
        end
    end
end

--[=[
    Accepts the join request, allowing the user into the group. Returns
    if the operation was successful.

    @return boolean
]=]
function JoinRequest:Accept ()
    local Success = self.Client:Request ("POST","https://groups.roblox.com/v1/groups/"..self.Group.Id.."/join-requests/users/"..self.User.Id)
    return Success
end

--[=[
    Declines the join request. Returns if the operation was successful.

    @return boolean
]=]
function JoinRequest:Decline ()
    local Success = self.Client:Request ("DELETE","https://groups.roblox.com/v1/groups/"..self.Group.Id.."/join-requests/users/"..self.User.Id)
    return Success
end

setmetatable(JoinRequest,JoinRequest)
return JoinRequest