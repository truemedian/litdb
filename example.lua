local Poller = require ('.')
local JSON = require ('json')
local FS = require('fs')
local Path = require('path')

local event_poller = Poller:new("https://api.github.com/rate_limit")

event_poller:on("data", function(data, response)
	local parsed = JSON.parse(data)
	p(parsed)
end)
event_poller:on("polling", function(...) p("Polling "..event_poller.url.."...") end)
event_poller:on("notmodified", function(...) p("Not Modified") end)
event_poller:on("error", function(err) p(err) end)
event_poller:on("intervalchange", function(old, new) p("Interval changed from "..old.." to "..new) end)

event_poller:start()
