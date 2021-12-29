--local ssl = require("ssl")
local http = require("coro-http")
local json = require("json")
local group = require("group")

function frequest (method,endpoint,headers,body)
    local response,responsebody = http.request(method,endpoint,headers,body)
    local returnHeaders = {}
    for i,v in pairs(response) do
        if type(v) == "table" then
            returnHeaders[v[1]] = v[2]
        else
            returnHeaders[i] = v
        end
    end
    local returnBody = {}
    returnBody = json.decode(responsebody)
    return returnHeaders,returnBody
end

local client = {}
client._type = "Client Class"

function client.__call (t)
    local self = {}
    setmetatable(self,{__index=t})

    local result = self:init ()
    if result == false then return nil end

    self._type = "Client Instance"

    return self
end

function client:init ()
    self.active = true
    self.group = group (self) -- creates a new group class with this client
end

function client:request (method,endpoint,headersparam,bodyparam)
    local headers = headersparam or {}
    headers[#headers+1] = {"X-CSRF-TOKEN",self.xcsrf}
    headers[#headers+1] = {"Content-Type","application/json"}
    headers[#headers+1] = {"Cookie",self.cookie}
    local body = ""
    if bodyparam ~= nil then
        body = json.encode(bodyparam)
    end
    headers,body = frequest (method,endpoint,headers,body)
    if headers["x-csrf-token"] ~= nil then
        self.xcsrf = headers["x-csrf-token"]
        if headers.code == 403 then
            headers = headersparam or {}
            headers[#headers+1] = {"X-CSRF-TOKEN",self.xcsrf}
            headers[#headers+1] = {"Content-Type","application/json"}
            headers[#headers+1] = {"Cookie",self.cookie}
            local body = ""
            if bodyparam ~= nil then
                body = json.encode(bodyparam)
            end
            headers,body = _request (method,endpoint,headers,body)
            if headers.code ~= 200 then
                return false,body["errors"][1]["message"]
            end
            return headers,body
        end
    end
    if headers.code ~= 200 then
        return false,body["errors"][1]["message"]
    end
    return true,headers,body
end

function client:setCookie (cookie)
    self.cookie = ".ROBLOSECURITY="..cookie
end

setmetatable(client,client)
return client