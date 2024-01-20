local prettyprint = require("pretty-print")
local http = require("coro-http")
local json = require("json")

local edulink = {}

edulink.school = nil
edulink.authentication = nil
edulink.learner = nil

-- dont even ask why the edulink api handles your sensitive info in plain, clear text...
function edulink.provision(school_postcode)
    if not school_postcode then return nil, "Required parameters weren't supplied!" end

    local payload = {
        id = "1",
        jsonrpc = "2.0",
        method = "School.FromCode",
        params = {
            code = school_postcode
        }
    }
    payload = json.encode(payload)

    local headers, body = http.request("POST", "https://provisioning.edulinkone.com/?method=School.FromCode", {
        {"Content-Type", "application/json;charset=UTF-8"},
        {"Content-Length", #payload}
    }, payload)

    body = json.decode(body)
    if not body or not body.result.success then
        local err = "Provisioning Error with HTTP ".. headers.code .." ".. headers.reason ..": ".. body.result.error
        error(err)
        return nil, err
    end

    edulink.school = body.result.provision

    return body.result.school, true
end



function edulink.authenticate(username, password, school_postcode)
    if not username or not password then return nil, "Required parameters weren't supplied!" end

    edulink.school = edulink.provision(school_postcode) or edulink.school

    local payload = {
        id = "1",
        jsonrpc = "2.0",
        method = "EduLink.Login",
        params = {
            establishment_id = edulink.school.school_id,
            username = username,
            password = password,
            from_app = false
        }
    }
    payload = json.encode(payload)

    local headers, body = http.request("POST", edulink.school.server .."?method=EduLink.Login", {
        {"Content-Type", "application/json;charset=UTF-8"},
        {"Content-Length", #payload},
        {"X-API-Method", "EduLink.Login"}
    }, payload)

    body = json.decode(body)
    if not body or not body.result.success or not body.result.authtoken then
        local err = "Authentication Error with HTTP ".. headers.code .." ".. headers.reason ..": ".. body.result.error
        error(err)
        return nil, err
    end

    edulink.authentication = body.result.authtoken
    edulink.learner = body.result.user

    print("lua-edulink: Authenticated as ".. body.result.user.forename)

    return body.result.authtoken, true
end



function edulink.timetable(date, learner_id)
    if not date then date = os.date("%Y-%m-%d", os.time()) end

    learner_id = learner_id or edulink.learner.id

    local payload = {
        id = "1",
        jsonrpc = "2.0",
        method = "EduLink.Timetable",
        params = {
            learner_id = edulink.learner.id,
            date = date
        }
    }
    payload = json.encode(payload)

    local headers, body = http.request("POST", edulink.school.server .."?method=EduLink.Timetable", {
        {"Content-Type", "application/json;charset=UTF-8"},
        {"Content-Length", #payload},
        {"X-API-Method", "EduLink.Timetable"},
        {"Authorization", "Bearer ".. edulink.authentication}
    }, payload)

    body = json.decode(body)
    if not body or not body.result.success or not body.result.weeks then
        local err = "Timetable Error with HTTP ".. headers.code .." ".. headers.reason ..": ".. body.result.error
        error(err)
        return nil, err
    end

    return body.result.weeks[1].days[1].lessons, true
end

return edulink