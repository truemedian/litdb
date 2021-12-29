local group = {}
group.__index = group
group._type = "Group SuperClass"

function group.__call (t,GroupIdentifier) -- creates a new instance. in this case t=s1
    local self = {} -- this is s2 in other comments
    setmetatable(self,{__index=function(_t,i)
        if t[i] then return t[i] end
        if t._requests[i] then t._requests[i](_t) return rawget(_t,i) end
    end})

    local result = self:init (GroupIdentifier)
    if result == false then return nil end

    self._type = "Group Instance"

    return self
end

function group:init (GroupIdentifier) -- self = s2. mt {__index=s1/_requests}
    local t = type(GroupIdentifier)
    if t == "number" then
        self.id = GroupIdentifier
    elseif t == "string" then
        local success,headers,body = self.client:request ("GET","https://groups.roblox.com/v1/groups/search/lookup?groupName="..GroupIdentifier)
        if success then
            if body["data"][1] ~= nil then
                local groupData = body["data"][1]
                self.id = groupData.id
                self.name = groupData.name
                self.memberCount = groupData.memberCount
            else
                --error("Lublox: Failed to find group from provided string.")
                return false
            end
        else
            --error("Lublox: Group Search request failed: "..headers)
            return false
        end
    elseif t == "table" then
        if GroupIdentifier["id"] then
            for i,v in pairs(GroupIdentifier) do
                self[i] = v
            end 
        else
            --error("Lublox: Failed to find index 'id' in table GroupIdentifier.")
            return false
        end
    end
end

local requestFunctions = {}

function requestFunctions.getGroupData (t) -- t = s2. mt {__index=s1/_requests}
    local success,headers,body = t.client:request ("GET","https://groups.roblox.com/v1/groups/"..t.id)
    if success then
        t.name = body.name
        t.description = body.description
        t.memberCount = body.memberCount
        t.publicEntryAllowed = body.publicEntryAllowed
    end
end

group._requests = {
    name = requestFunctions.getGroupData,
}

return function (client) -- creates a new group class with the given client
    local self = {} -- this is s1 in other comments
    self.client = client -- sets the client of class
    self.__index = self -- sets the __index of the class, so that instances reference to this
    setmetatable(self,group) -- sets the metatable of the class to group, so that this table can get methods from group
    self._type = "Group Class"
    return self
end