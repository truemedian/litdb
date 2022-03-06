local DateTime = require("util/datetime")

--[=[
    @within Group
    @prop Id number
    @readonly
    The GroupId of the group.
]=]
--[=[
    @within Group
    @prop Client Client
    @readonly
    A reference back to the client that owns this object.
]=]
--[=[
    @within Group
    @prop Name string
    @readonly
    The name of the group.
]=]
--[=[
    @within Group
    @prop Description strimg
    @readonly
    The description of the group.
]=]
--[=[
    @within Group
    @prop MemberCount number
    @readonly
    The number of members the group has.
]=]
--[=[
    @within Group
    @prop PublicEntryAllowed boolean
    @readonly
    If users are able to join the group without pending.
]=]
--[=[
    @within Group
    @prop Owner User?
    @readonly
    The owner of the group.
]=]
--[=[
    @within Group
    @prop ShoutBody string?
    @readonly
    The shout of the group.
]=]
--[=[
    @within Group
    @prop ShoutPoster User?
    @readonly
    The user that posted the shout.
]=]
--[=[
    @within Group
    @prop ShoutCreated number?
    @readonly
    When the shout was created (unix time). 
]=]
--[=[
    @within Group
    @prop ShoutUpdated number?
    @readonly
    When the shout was updated (unix time).
]=]
--[=[
    @within Group
    @prop Roles {Role}
    @readonly
    The roles in the group.
]=]
--[=[
    @within Group
    @prop Members PageCursor
    @readonly
    A PageCursor object that returns pages of members.
]=]
--[=[
    @within Group
    @prop JoinRequests PageCursor
    @readonly
    A PageCursor object that returns pages of join requests.
]=]
--[=[
    The group object can view and edit data about groups.

    @class Group
]=]
local Group = {}

--[=[
    Constructs a group object.

    @param _ Group
    @param Client Client -- The client to make requests with.
    @param GroupId number -- The GroupId of the group.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return Group
]=]
function Group.__call (_,Client,GroupId,Data)
    local self = {}
    setmetatable(self,{__index=function (t,i)
        if Group[i] then return Group[i] end
        if Group._Requests[i] then
            Group._Requests[i](t) 
            return rawget(t,i)
        end
    end})

    self.Client = Client
    self.Id = GroupId

    if type(Data) == "table" then
        for i,v in pairs(Data) do
            self[i] = v
        end
    end

    return self
end

--[=[
    Gets data about the group.

    @return {Name:string,Description:string,MemberCount:number,PublicEntryAllowed:boolean,Owner:User?,ShoutBody:string?,ShoutCreated:number?,ShoutUpdated:number?,ShoutPoster:User?}
]=]
function Group:GetData ()
    local Success,Body = self.Client:Request ("GET","https://groups.roblox.com/v1/groups/"..self.Id)
    if Success then
        local Data = {}
        Data.Name = Body.name
        Data.Description = Body.description
        Data.MemberCount = Body.memberCount
        Data.PublicEntryAllowed = Body.publicEntryAllowed
        if Body.owner then
            Data.Owner = self.Client:User (Body.owner.userId,{
                Name = Body.owner.username,
                DisplayName = Body.owner.displayName,
            })
        end
        if Body.shout then
            Data.ShoutBody = Body.shout.body
            Data.ShoutCreated = DateTime (Body.shout.created)
            Data.ShoutUpdated = DateTime (Body.shout.updated)
            if Body.shout.poster then
                Data.ShoutPoster = self.Client:User (Body.shout.poster.userId,{
                    Name = Body.shout.poster.username,
                    DisplayName = Body.shout.poster.displayName,
                })
            end
        end
        for i,v in pairs(Data) do
            self[i] = v
        end
        return Data
    end
end

--[=[
    Gets the roles in the group.

    @return {Role}
]=]
function Group:GetRoles ()
    local Success,Body = self.Client:Request ("GET","https://groups.roblox.com/v1/groups/"..self.Id.."/roles")
    if Success then
        self.Roles = {}
        for _,v in pairs(Body.roles) do
            self.Roles[#self.Roles+1] = self.Client:Role (v.id,{Name=v.name,Rank=v.rank,MemberCount=v.memberCount})
        end
        return self.Roles
    end
end

--[=[
    Gets all members in the group.

    @return PageCursor
]=]
function Group:GetMembers ()
    self.Members = self.Client:PageCursor ("https://groups.roblox.com/v1/groups/"..self.Id.."/users",{},function (v)
        return self.Client:Member (
            self,
            self.Client:User(v.user.userId,{Name=v.user.username,DisplayName=v.user.displayName}),
            {Role=self.Client:Role(v.role.id,{Name=v.role.name,Description=v.role.description,Rank=v.role.rank,MemberCount=v.role.memberCount}),Valid=true}
        )
    end)
    return self.Members
end

--[=[
    Gets a member by user. Will return nil if the user is not in the group.

    @param User User|number -- The UserId or User object.
    @return Member?
]=]
function Group:GetMemberFromUser (User)
    return self.Client:Member (self,User)
end

--[=[
    Gets all join requests for the group.

    @return PageCursor
]=]
function Group:GetJoinRequests ()
    self.JoinRequests = self.Client:PageCursor ("https://groups.roblox.com/v1/groups/"..self.Id.."/join-requests",{},function (v)
        return self.Client:JoinRequest (
            self,
            self.Client:User (v.requester.userId,{Name=v.requester.username,DisplayName=v.requester.displayName}),
            {Valid=true}
        )
    end)
    return self.JoinRequests
end

--[=[
    Gets a join request by user.

    @param User User|number -- The UserId or User object.
    @return JoinRequest?
]=]
function Group:GetJoinRequestFromUser (User)
    return self.Client:JoinRequest (self,User)
end

--[[
--[=[
    Gets a pages object for all group wall posts.

    @return PageCursor
]=]
function Group:GetWall ()
    self.Wall = self.Client:PageCursor ("https://groups.roblox.com/v2/groups/1/wall/posts",nil,function (v)
        -- add wallpost class
    end)
end
--]]

Group._Requests = {
    Name = Group.GetData,
    Description = Group.GetData,
    MemberCount = Group.GetData,
    PublicEntryAllowed = Group.GetData,
    Owner = Group.GetData,
    ShoutBody = Group.GetData,
    ShoutPoster = Group.GetData,
    ShoutCreated = Group.GetData,
    ShoutUpdated = Group.GetData,

    Roles = Group.GetRoles,

    Members = Group.GetMembers,

    JoinRequests = Group.GetJoinRequests,
}

setmetatable(Group,Group)
return Group