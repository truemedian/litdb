local DateTime = require("util/datetime")

--[=[
    @within User
    @prop Id number
    @readonly
    The UserId of the user.
]=]
--[=[
    @within User
    @prop Client Client
    @readonly
    A reference back to the client that owns this object.
]=]
--[=[
    @within User
    @prop Name string
    @readonly
    The Username of the user.
]=]
--[=[
    @within User
    @prop Description string
    @readonly
    The description (about me) of the user.
]=]
--[=[
    @within User
    @prop Created number
    @readonly
    The creation date/time (unix time) of the user.
]=]
--[=[
    @within User
    @prop IsBanned boolean
    @readonly
    If the user is banned or not.
]=]
--[=[
    @within User
    @prop DisplayName string
    @readonly
    The display name of the user.
]=]
--[=[
    @within User
    @prop Friends {User}
    @readonly
    A list of users the user is friended to.
]=]
--[=[
    @within User
    @prop FriendCount number
    @readonly
    The number of friends this user has.
]=]
--[=[
    @within User
    @prop Followers PageCursor
    @readonly
    A pages object of users that follow this user.
]=]
--[=[
    @within User
    @prop FollowerCount number
    @readonly
    The number of followers this user has.
]=]
--[=[
    @within User
    @prop Following PageCursor
    @readonly
    A pages object of users that this user follows.
]=]
--[=[
    @within User
    @prop FollowingCount number
    @readonly
    The number of users that this user follows.
]=]
--[=[
    @within User
    @prop Groups {Member}
    @readonly
    The member object for every group the user is in.
]=]
--[=[
    @within User
    @prop PresenceType PresenseTypeEnum
    @readonly
    The presense of the user.
]=]
--[=[
    @within User
    @prop LastLocation string
    @readonly
    The last recorded location of the user. This is relatively undocumented.
]=]
--[=[
    @within User
    @prop PlaceId number
    @readonly
    The current placeid of the user.
]=]
--[=[
    @within User
    @prop RootPlaceId number
    @readonly
    The root placeid of the game they are in.
]=]
--[=[
    @within User
    @prop GameId string
    @readonly
    Unknown?
]=]
--[=[
    @within User
    @prop UniverseId number
    @readonly
    Unknown?
]=]
--[=[
    @within User
    @prop LastOnline number
    @readonly
    The last time the user was online. In unix time.
]=]
--[=[
    The user object can view and edit data about users.

    @class User
]=]
local User = {}

--[=[
    Constructs a user object.

    @param _ User
    @param Client Client -- The client to make requests with.
    @param UserId number|string -- The Username or UserId.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return User
]=]
function User.__call (_,Client,UserId,Data)
    local self = {}
    setmetatable(self,{__index=function (t,i)
        if User[i] then return User[i] end
        if User._Requests[i] then
            User._Requests[i](t)
            return rawget(t,i)
        end
    end})

    self.Client = Client

    if type(Data) == "table" then
        for i,v in pairs(Data) do
            self[i] = v
        end
    end

    if type(UserId) == "number" then
        self.Id = UserId
    elseif type(UserId) == "string" then
        local Success,Body = self.Client:Request("POST","https://users.roblox.com/v1/usernames/users",{},{},{usernames={UserId},excludeBannedUsers=true})
        if Success then
            Success = false
            for _,v in pairs(Body["data"]) do
                if string.lower(v.name) == string.lower(UserId) then
                    self.Id = v.id
                    self.Name = v.name
                    self.DisplayName = v.displayName
                    Success = true
                    break
                end
            end
            if Success == false then
                return nil
            end
        else
            return nil
        end
    end

    return self
end

--[=[
    Gets data about the user.

    @return {Name:string,Description:string,Created:number,IsBanned:boolean,DisplayName:string}
]=]
function User:GetData ()
    local Success,Body = self.Client:Request ("GET","https://users.roblox.com/v1/users/"..self.Id)
    if Success then
        local Data = {}
        Data.Name = Body.name
        Data.Description = Body.description
        Data.Created = DateTime(Body.created)
        Data.IsBanned = Body.isBanned
        Data.DisplayName = Body.displayName
        for i,v in pairs(Data) do
            self[i] = v
        end
        return Data
    end
end

--[=[
    Gets the users friends.

    @return {User}
]=]
function User:GetFriends ()
    local Success,Body = self.Client:Request ("GET","https://friends.roblox.com/v1/users/"..self.Id.."/friends",{userSort="Alphabetical"})
    if Success then
        self.Friends = {}
        for _,v in pairs(Body["data"]) do
            self.Friends[#self.Friends+1] = self.Client:User (v.id,{
                Description = v.description,
                Name = v.name,
                DisplayName = v.displayName,
                Created = DateTime(v.created),
                IsBanned = v.isBanned,
            })
        end
        self.FriendCount = #self.Friends
        return self.Friends
    end
end

--[=[
    Gets the number of friends the user has.

    @return number
]=]
function User:GetFriendCount ()
    local Success,Body = self.Client:Request ("GET","https://friends.roblox.com/v1/users/"..self.Id.."/friends/count")
    if Success then
        self.FriendCount = Body["count"]
        return Body["count"]
    end
end

--[=[
    Gets a pages object that returns the user's followers as user objects.

    @return PageCursor
]=]
function User:GetFollowers ()
    self.Followers = self.Client:PageCursor ("https://friends.roblox.com/v1/users/"..self.Id.."/followers",nil,function (v)
        return self.Client:User (v.id,{Name=v.name,DisplayName=v.displayName,Created=DateTime(v.created),Description=v.description,IsBanned=v.isBanned})
    end)
    return self.Followers
end

--[=[
    Gets the number of users that follow this user.

    @return number
]=]
function User:GetFollowerCount ()
    local Success,Body = self.Client:Request ("GET","https://friends.roblox.com/v1/users/"..self.Id.."/followers/count")
    if Success then
        self.FollowerCount = Body["count"]
        return Body["count"]
    end
end

--[=[
    Gets a pages object that returns the users this user follows as user objects.

    @return PageCursor
]=]
function User:GetFollowing ()
    self.Following = self.Client:PageCursor ("https://friends.roblox.com/v1/users/"..self.Id.."/followings",nil,function (v)
        return self.Client:User (v.id,{Name=v.name,DisplayName=v.displayName,Created=DateTime(v.created),Description=v.description,IsBanned=v.isBanned})
    end)
    return self.Following
end

--[=[
    Gets the number of users that this user is following.

    @return number
]=]
function User:GetFollowingCount ()
    local Success,Body = self.Client:Request ("GET","https://friends.roblox.com/v1/users/"..self.Id.."/followings/count")
    if Success then
        self.FollowingCount = Body["count"]
        return Body["count"]
    end
end

--[=[
    Gets the member object for every group the user is in.

    @return {Member}
]=]
function User:GetGroups ()
    local Success,Body = self.Client:Request ("GET","https://groups.roblox.com/v2/users/"..self.Id.."/groups/roles")
    if Success then
        self.Groups = {}
        for _,v in pairs(Body.data) do
            self.Groups[#self.Groups+1] = self.Client:Member (
                self.Client:Group (v.group.id,{
                    Name = v.group.name,
                    MemberCount = v.group.memberCount,
                }),
                self,
                {
                    Role = self.Client:Role (v.role.id,{
                        Name = v.role.name,
                        Rank = v.role.rank,
                    })
                }
            )
        end
        return self.Groups
    end
end

--[=[
    Returns if the user owns the gamepass.

    @param GamepassId number -- The gamepass ID
    @return boolean
]=]
function User:OwnsGamepass (GamepassId)
    local Success,Body = self.Client:Request ("GET","https://inventory.roblox.com/v1/users/"..self.Id.."/items/GamePass/"..GamepassId)
    if Success then
        return Body.data[1] ~= nil
    end
end

--[=[
    Returns if the user owns the badge.

    @param BadgeId number -- The badge ID
    @return boolean
]=]
function User:OwnsBadge (BadgeId)
    local Success,Body = self.Client:Request ("GET","https://inventory.roblox.com/v1/users/"..self.Id.."/items/Badge/"..BadgeId)
    if Success then
        return Body.data[1] ~= nil
    end
end

--[=[
    Gets the presense data of the user.

    @return {PresenceType:PresenceTypeEnum,LastLocation:string,PlaceId:number,RootPlaceId:number,GameId:string,UniverseId:number,LastOnline:number}
]=]
function User:GetPresenseData ()
    local Success,Body = self.Client:Request ("POST","https://presence.roblox.com/v1/presence/users",nil,nil,{userIds={self.Id}})
    if Success then
        if not Body.userPresences then return end
        if not Body.userPresences[1] then return end
        Body = Body.userPresences[1]
        local Data = {}
        Data.PresenceType = Body.userPresenceType
        Data.LastLocation = Body.lastLocation
        Data.PlaceId = Body.placeId
        Data.RootPlaceId = Body.rootPlaceId
        Data.GameId = Body.gameId
        Data.UniverseId = Body.universeId
        Data.LastOnline = DateTime(Body.lastOnline)
        for i,v in pairs(Data) do
            self[i] = v
        end
        return Data
    end
end

User._Requests = {
    Name = User.GetData,
    Description = User.GetData,
    Created = User.GetData,
    IsBanned = User.GetData,
    DisplayName = User.GetData,

    Friends = User.GetFriends,
    FriendCount = User.GetFriendCount,

    Followers = User.GetFollowers,
    FollowerCount = User.GetFollowerCount,
    Following = User.GetFollowing,
    FollowingCount = User.GetFollowingCount,

    Groups = User.GetGroups,

    PresenceType = User.GetPresenseData,
    LastLocation = User.GetPresenseData,
    PlaceId = User.GetPresenseData,
    RootPlaceId = User.GetPresenseData,
    GameId = User.GetPresenseData,
    UniverseId = User.GetPresenseData,
    LastOnline = User.GetPresenseData,
}

setmetatable(User,User)
return User