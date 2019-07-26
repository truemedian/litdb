local p = require('pretty-print').prettyPrint
local miniz = require('miniz')
local luviPath = require('luvipath')
local pathJoin = luviPath.pathJoin
local fs = require 'coro-fs'
local blake2s = require 'blake2s'
local getType = require("mime").getType

return function (basePath)

    local function loadMpk(package, expectedHash)
        local data = fs.readFile(pathJoin(basePath, package))
        if not data then return nil, "No such mpk package '" .. package .. "' in basepath '" .. basePath .. "'" end
        local hash = blake2s.hash(data, 32, nil, 'hex')
        if expectedHash and expectedHash ~= hash then
            return nil, "Expected hash " .. expectedHash .. " but got " .. hash
        end
        return data, hash
    end

    local function sendMpk(package, hash, res, go)
        local mpk
        print("Loading", package)
        mpk, hash = loadMpk(package, hash)
        if not mpk then return go(hash) end
        res.code = 200
        res.headers["Content-Type"] = "application/zip"
        res.headers["ETag"] = '"' .. hash .. '"'
        res.body = mpk
    end

    local function sendFile(package, mpkHash, path, res, go)
        local zip = miniz.new_reader(pathJoin(basePath, package))
        if not zip then return go("No such zip file: " .. package) end
        if path:sub(1,1) == "/" then path = path:sub(2) end
        local index = zip:locate_file(path)
        if not index then
            if not zip then return go("No such file inside zip: " .. package .. path) end
        end
        local body = zip:extract(index)
        local hash = blake2s.hash(body, 32, nil, 'hex')
        res.code = 200
        res.headers["Content-Type"] = getType(path)
        res.headers["ETag"] = '"' .. hash .. '"'
        res.body = body
    end

    return function (req, res, go)
        local hash, package, path
        path = req.params.path
        local a, b = path:find("^[0-9a-f]+/")
        if a and ((b - a) >= 40) then
            hash = path:sub(a, b - 1)
            path = path:sub(b + 1)
            p{hash=hash}
        end
        package, path = path:match("^([^/]+%.mpk)(.*)")
        if not package then return go() end

        if path == "" then
            return sendMpk(package, hash, res, go)
        end
        return sendFile(package, hash, path, res, go)
    end

end