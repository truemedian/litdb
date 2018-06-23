local request = require "coro-http".request
local decode = require "json".decode
local endpoints = require "../endpoints"
local format = string.format

local api = {}

return function(id, callback)
    if type(id) ~= "number" then return error(id.." is not a number.") end
    if math.floor(id) ~= id then return error(id.." is not a full number. No decimals.") end
    local info = {}
    coroutine.wrap(function()
        local _,body = request("GET", format(endpoints.assetInfo, id))

        local info = decode(body)

    	info = {
    		name = info.Name,
    		description = info.Description,
    		creator = {
                name = info.Creator.Name,
                id = info.Creator.Id,
                creatorType = string.lower(info.Creator.CreatorType),
            },
            created = info.Created,
            lastUpdate = info.Updated,
            price = info.PriceInRobux,
            sales = info.Sales,
            isNew = info.IsNew,
            isForSale = info.IsForSale,
            isLimited = info.IsLimited,
            isLimitedUnique = info.IsLimitedUnique,
            remaining = info.Remaining
    	}

        callback(info)
    end)()
end
