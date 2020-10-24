local http = require("coro-http");
local json = require("json");
local logger = require("./dependencies/logger");
local api = {};
local internal = {};

function internal:formatCookies(cookies)
    local response = {};
    for _,cookie in pairs(cookies) do 
        table.insert(response,string.format("%s=%s",cookie[1],cookie[2]));
    end

    return table.concat(response,"; ");
end

function internal:makeHeaders(headers,cookies)
    local format = {};
    headers = headers or {};
    cookies = cookies or {};

    for _,header in pairs(headers) do 
        if(header[1] and header[2] ~= nil) then
            if(header[1]:lower() == "Cookie") then 
                error("You cannot add a cookie header!");
            else 
                table.insert(format,{header[1],header[2]})
            end
        end
    end

    if(#cookies >= 1) then
        table.insert(format,{"Cookie",internal:formatCookies(cookies)})
    end

    return format;
end

function api.request(url,method,headers,body,authentication)    
    local postMethods = {
        ["POST"] = true,
        ["PATCH"] = true
    }

    local regularMethods = {
        ["GET"] = true,
        ["DELETE"] = true,
    }

    if(postMethods[method]) then 
        if(body == nil) then 
            body = {};
        end 

        if(authentication ~= nil) then 
            return coroutine.wrap(function(callback)
                local response,body = http.request(method,url,internal:makeHeaders(headers,{{".ROBLOSECURITY",authentication}}),json.encode(body));
                if(callback) then 
                    callback(response,body) 
                end;            
            end)
        else
            return coroutine.wrap(function(callback)
                local response,body = http.request(method,url,internal:makeHeaders(headers),json.encode(body));
                if(callback) then 
                    callback(response,body) 
                end;
            end)
        end
    elseif(regularMethods[method]) then 
        if(authentication ~= nil) then 
            return coroutine.wrap(function(callback)
                local response,body = http.request(method,url,internal:makeHeaders(headers,{{".ROBLOSECURITY",authentication}}));
                if(callback) then 
                    callback(response,body) 
                end;            
            end)
        else
            return coroutine.wrap(function(callback)
                local response,body = http.request(method,url,internal:makeHeaders(headers));
                if(callback) then 
                    callback(response,body) 
                end;
            end)
        end
    else
        error("Invalid method!");
    end
end

function api.getXCSRF(cookie,callback)
    local headers = {
        {"Content-Type","application/json"};
        {"Content-Length",0};
        {"X-CSRF-TOKEN",nil};
    };

    api.request("https://groups.roblox.com/v1/groups/0/status","PATCH",headers,{},cookie)(function(response,body)
        for _,v in pairs(response) do 
            if(type(v) == "table") then
                if(v[1]:lower() == "x-csrf-token") then 
                    callback(v[2]);
                    return;
                end
            end
        end
        
        logger:log(2,"XCRSF token not found!");
    end);
end

return api;