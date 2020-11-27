--[[lit-meta
  name = "dustin10weering/luvit-yt-searcher"
    version = "1.2"
    homepage = "https://github.com/dustin10weering/luvit-yt-searcher"
    dependencies = {
		'creationix/coro-http@3.1.0'
	}
    description = "Uses youtube api from google to search youtube videos."
    tags = {
        "yt",
        "searcher",
        "luvit",
	    "youtube",
	    "search"
    }
    license = "MIT"
    author = "dustin10weering"
]]

-- searches video on youtube, made by dustin.
-- uses the coro-http module from luvit itself
--[[ 
HOW TO USE:
require it with something like "local ytsearcher = require('luvit-yt-searcher').new(YOUTUBE_API_KEY as string)"
then search a video with it like "local searcher = ytsearcher:search('banana+phone')"
because this function is async, you will need to use a coroutine.
Now you can do something like this:
local ytsearcher = require('ytsearcher').new(YOUTUBE_API_KEY as string)
local search = coroutine.wrap(function()
    local video,response = ytsearcher:search('banana+phone')
    print(video.id) -- youtube video id
    print(video.title) -- video title
    print(video.thumbnail) -- thumbnail link
    print(video.author) -- author name
end)
search()
When there's an error, it will return nil (and as second argument the response if it cannot connect to the website).
]]

local http = require('coro-http')

local apiurl = "https://www.googleapis.com/youtube/v3/search?"

local function find(body,term)
    local begin, last = body:find(term)
    if last then
        local last2 = body:find('"', last+3)
        return body:sub(last+3,last2-1)
    else
        return ""
    end
end

local module = {}
module.__index = module

module.new = function (ytkey,regioncode)
    local classSelf = {}
    setmetatable(classSelf, module)
    classSelf.key = ytkey
    return classSelf
end

function module:search(searchparam,regioncode)
    local searchParams = { -- note: you can add more if they are listed in the youtube api docs.
        key = self.key,
        maxResults = 1,
        part = 'snippet',
        q = searchparam,
        regionCode = regioncode or "US",
        type = 'video'
    }
    local queryUrl = ""
    for param,info in pairs(searchParams) do
        queryUrl = queryUrl.."&"..param.."="..info
    end
    queryUrl = string.sub(queryUrl,2)
    local response,body = http.request("GET",apiurl..queryUrl)
    if not body then
        return nil,response
    end
	-- some failsaves
	if body:find('API key not valid') then
	    return nil, "Invalid api key! See https://github.com/dustin10weering/luvit-yt-searcher."
	end
	if body:find('"status": "INVALID_ARGUMENT"') then
	    print("Invalid arguments! Invalid url: "..apiurl..queryUrl)
	    local from = body:find('"message":')
		if from then
		    return nil, "Invalid arguments! "..find(body,'"message":')
		else
		    return nil, "Invalid arguments! See console for not-working url."
		end
	end
	if body:find('"totalResults": 0') then
	    return nil, "No results"
	end
    local from = body:find('"high":')
    if from then
	    from = nil
	else
        from = "" -- (empty thumbnail string) no thumbnail given back
    end
	--
    local videoinfo = {
        id = find(body,'"videoId":'),
        title = find(body,'"title":'),
        thumbnail = from or find(body,'"url":',from),
        author = find(body,'"channelTitle":')
    }
    return videoinfo
end

return module
