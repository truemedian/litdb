local http = require("coro-http")
local json = require("json")
local qs = require("querystring")

local User = require("user")

local Group = require("group/group")
local Role = require("group/role")
local Member = require("group/member")
local JoinRequest = require("group/joinRequest")

local Pages = require("util/pages")

local function MakeRequest (Method,Endpoint,Headers,Body)
    local HeadersActual = {}
    for i,v in pairs(Headers) do
        HeadersActual[#HeadersActual+1] = {i,v}
    end
    local Response,ResponseBody = http.request(Method,Endpoint,HeadersActual,Body)
    local ReturnHeaders = {}
    for i,v in pairs(Response) do
        if type(v) == "table" then
            ReturnHeaders[v[1]] = v[2]
        else
            ReturnHeaders[i] = v
        end
    end
    local ReturnBody = {}
    ReturnBody = json.decode(ResponseBody)
    return ReturnHeaders,ReturnBody
end

--[=[
    @within Client
    @prop Cookie string
    @readonly
    The cookie of the authenticated user to be used in requests.
]=]
--[=[
    @within Client
    @prop Token string
    @readonly
    The X-CSRF-TOKEN to be used in requests.
]=]
--[=[
    The client manages all requests, and provides access to objects like Group and User.

    @class Client
]=]
local Client = {}

--[=[
    Constructs a client object.

    @return Client
]=]
function Client.__call ()
    local self = {}
    setmetatable(self,{__index=function (t,i)
        if Client[i] then return Client[i] end
        if Client._Requests[i] then
            Client._Requests[i](t)
            return rawget(t,i)
        end
    end})

    return self
end

--[=[
    Constructs a Group object.

    @param GroupId number -- The GroupId of the group.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return Group
]=]
function Client:Group (GroupId,Data)
    return Group (self,GroupId,Data)
end

--[=[
    Constructs a Role object.

    @param RoleId number -- The RoleId of the role.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return Role
]=]
function Client:Role (RoleId,Data)
    return Role (self,RoleId,Data)
end

--[=[
    Constructs a Member object.

    @param GroupId number|Group -- The group that the member object is a member of.
    @param UserId number|User -- The user that the member is for.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return Member
]=]
function Client:Member (GroupId,UserId,Data)
    return Member (self,GroupId,UserId,Data)
end

--[=[
    Constructs a User object.

    @param UserId number|string -- The UserId or Username of the user.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return Role
]=]
function Client:User (UserId,Data)
    return User (self,UserId,Data)
end

--[=[
    Constructs a PageCursor object. This is used within the library, but it can be used yourself.

    @param Endpoint string -- The endpoint to get pages from.
    @param Tags {[string]=any} -- Optional list of tags to add on to the request.
    @param Interpret function -- The function that interprets recieved data, to turn it into a useable format.
    @param SortOrder string? -- The sort order to use when requesting for pages. Can be "Asc" or "Desc".
    @param Limit number? -- The page item limit to use when requesting pages.
    @param PageDataLocation string? -- The location where page data is located for non-standard pages.
    @param PageNextLocation string? -- The location where the next page cursor is found for non-standard pages.
    @param PagePreviousLocation string? -- The location where the previous page cursor is found for non-standard pages.
    @param CursorTag string? -- The name of the tag to send the cursor for non-standard pages.
    @param LimitTag string? -- The name of the tag to send the limit for non-standard pages.
    @param SortOrderTag string? -- The name of the tag to send the sort order for non-standard pages.
    @return PageCursor
]=]
function Client:PageCursor (Endpoint,Tags,Interpret,SortOrder,Limit,PageDataLocation,PageNextLocation,PagePreviousLocation,CursorTag,LimitTag,SortOrderTag)
    return Pages.PageCursor(self,Endpoint,Tags,Interpret,SortOrder,Limit,PageDataLocation,PageNextLocation,PagePreviousLocation,CursorTag,LimitTag,SortOrderTag)
end

--[=[
    Constructs a JoinRequest object.

    @param GroupId Group|number -- The Group or GroupId that join request is for.
    @param UserId User|number -- The User or UserId that made the join request.
    @param Data {[any]=any} -- Optional preset data. Used within the library, not meant for general use.
    @return JoinRequest
]=]
function Client:JoinRequest (GroupId,UserId,Data)
    return JoinRequest (self,GroupId,UserId,Data)
end

--[=[
    Authenticates the client, once authenticated the client cannot be deauthenticated.

    @param Cookie string -- The cookie to authenticate the client with.
]=]
function Client:Authenticate (Cookie)
    self.Cookie = ".ROBLOSECURITY="..Cookie
    local Success = self:Request ("GET","https://users.roblox.com/v1/users/authenticated")
    assert(Success,"Lublox: Failed to authenticate!")
end

--[=[
    Makes a HTTP request with the client's Cookie and X-CSRF-TOKEN.

    @param Method string -- The HTTP method to use.
    @param Endpoint string -- The target URL.
    @param Tags {[string]=any} -- Optional tags (querystrings) to add to the request.
    @param Headers {[string]=any} -- Optional headers to add to the request.
    @param Body {[any]=any} -- Optional body to send with the request.
    @return boolean -- If the request was successful (code 200)
    @return {[number|string]=any} -- The body of the response.
    @return {[string]=any} -- The headers of the response.
]=]
function Client:Request (Method,Endpoint,Tags,Headers,Body)
    if Tags then
        Endpoint = Endpoint.."?"..qs.stringify(Tags)
    end
    local H = Headers or {}
    if Method ~= "GET" then
        H["X-CSRF-TOKEN"] = self.Token
        H["Content-Type"] = "application/json"
    end
    H["Cookie"] = self.Cookie
    local B = nil
    if Body then
        B = json.encode (Body)
    end
    local HR,BR = MakeRequest (Method,Endpoint,H,B)
    if HR["x-csrf-token"] ~= nil then
        self.Token = HR["x-csrf-token"]
        if HR["code"] == 403 then
            H["X-CSRF-TOKEN"] = self.Token
            H["Cookie"] = self.Cookie
            HR,BR = MakeRequest (Method,Endpoint,H,B)
            return HR["code"] == 200,BR,HR
        end
        return HR["code"] == 200,BR,HR
    end
    return HR["code"] == 200,BR,HR 
end

Client._Requests = {
    
}

setmetatable(Client,Client)
return Client