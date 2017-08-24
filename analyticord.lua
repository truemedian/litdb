-- Some random lib which tries to add analyticord functionality to Lua, allowing you to use it in
-- Discordia, for example. Nothing too fancy.

local json = require "json"
local request = require("coro-http").request
local prettyPrint = require('pretty-print')

local function unpack_or_nil(...)
    local things = {...}
    if #things == 0 then return nil end
    return unpack(things)
end

-- Some Result-ish functions which aim to make the code more readable, overall.
local function err(...)
    return false, unpack_or_nil(...)
end

local function ok(...)
    return true, unpack_or_nil(...)
end

local function try(...)
    local result = {...}
    return {
        -- Return the values but throw when it's an error.
        unwrap = function()
            if result[1]then
                return select(2, unpack(result))
            else
                return error(result[2], 2)
            end
        end;
        -- Return the values or fallback to the default.
        unwrap_or_else = function(...)
            if resutl[1] then
                return select(2, unpack(result))
            else
                return ok(...)
            end
        end;
        -- Return true if the value is ok
        is_ok = function() return result[1] == true end;
        -- Return true if the value is err.
        is_err = function() return result[1] == false end;
        -- Just return the result, without doing special stuff. Useful for external handling
        get = function() return select(2, unpack(result)) end;
    }
end

-- Don't take this too seriously. Just messing with the AC devs.
local anal = {
    url = "https://analyticord.solutions"
}

-- Local function to make requests easier
local function _make_request(method, content_type, endpoint, data)
    local headers = {
        {"Content-Type", content_type},
        {"Authorization", anal.token}
    }
    local headers, body = request(method, anal.url .. endpoint, headers, data)
    return ok(headers, body)
end

local function make_request(...) return try(_make_request(...)) end

-- Checks if the token provided (if any) is valid by sending a request to the login endpoint.
function anal._check_login()
    if not anal.token then
        return err "Token not supplied"
    end
    local headers, body = make_request("GET", "application/json", "/api/botLogin").unwrap()
    if headers.code == 200 then
        return ok()
    else
        return err(json.parse(body))
    end
end

function anal._set_token(token)
    anal.token = token
    return ok()
end

function anal._submit_event(event, data)
    local header, body = make_request("POST", "application/x-www-form-urlencoded", 
                                      "/api/submit", "eventType=" .. event .. "&data=" .. data)
                                      .unwrap()
    local answer = json.parse(body)
    if header.code == 200 then return ok(answer) else return err(answer) end
end

-- wrap all analyticord functions in try calls
for k,v in pairs(anal) do
    if(k:sub(1,1) == "_") then
        anal[k:sub(2, #k)] = function(...) return try(anal[k](...)) end
    end
end

return anal
