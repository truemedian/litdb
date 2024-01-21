local http = require("coro-http")
local json = require("json")

local edulink = {}

edulink.school = nil
edulink.authentication = nil
edulink.learner = nil

function edulink.rawrequest(request_type, provisionUrl, method, headers, params)
    if not request_type or not method then return nil, "Required parameters not supplied." end

    if not headers then headers = {} end
    if not params then params = {} end

    local payload = {}
    payload.id = "1"
    payload.jsonrpc = "2.0"
    payload.method = method
    payload.params = params
    encoded_payload = json.encode(payload)

    headers["Content-Type"] = "application/json;charset=UTF-8"
    headers["Content-Length"] = #encoded_payload
    headers["X-API-Method"] = method

    if edulink.authentication then
        headers.Authorization = "Bearer ".. edulink.authentication
    end

    local formattedHeaders = {}
    for i,v in pairs(headers) do
        table.insert(formattedHeaders, {i, v})
    end

    local response_headers, body = http.request(request_type, provisionUrl .."?method=".. method, formattedHeaders, encoded_payload)

    body = json.decode(body)
    if not body or not body.result.success then
        errmsg = body.result.error or "No error provided by EduLink API"
        local err = "Error in request with HTTP ".. response_headers.code .." ".. response_headers.reason ..": ".. errmsg
        error(err)
        return nil, err
    end

    return body.result, true
end


-- dont even ask why the edulink api handles your sensitive info in plain, clear text...
function edulink.provision(school_postcode)
    if not school_postcode then return nil, "School postcode is invalid or wasn't supplied!" end

    local result, err = edulink.rawrequest("POST", "https://provisioning.edulinkone.com/", "School.FromCode", nil, {code = school_postcode})

    edulink.school = result.school

    return result.school, err
end



function edulink.authenticate(username, password, school_postcode)
    if not username or not password or (not school_postcode and not edulink.school) then return nil, "Required parameters weren't supplied!" end

    edulink.school = edulink.provision(school_postcode) or edulink.school

    local result, err = edulink.rawrequest("POST", edulink.school.server, "EduLink.Login", nil, {
        establishment_id = edulink.school.school_id,
        username = username,
        password = password,
        from_app = false
    })

    edulink.authentication = result.authtoken
    edulink.learner = result.user

    print("lua-edulink: Authenticated as ".. result.user.forename)

    return result.authtoken, true
end

function edulink.timetable(date, learner_id)
    date = date or os.time()
    if type(date) == "number" then date = os.date("%Y-%m-%d", date) end

    learner_id = learner_id or edulink.learner.id

    local result, err = edulink.rawrequest("POST", edulink.school.server, "EduLink.Timetable", nil, {
        learner_id = edulink.learner.id,
        date = date
    })

    local found = nil
    for i,v in pairs(result.weeks) do
        for ii, vv in pairs(v.days) do
            if vv.date == date then
                found = vv.lessons
            end
        end
    end

    if not found then return nil, "Failed to find lessons on that day. Maybe there are no lessons?" end

    return found, true
end

return edulink