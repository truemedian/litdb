local http = require "http"
local querystring = require "./querystring"
local json_encode = (require "./ljson").encode

local fly_ticket = {}

function fly_ticket:render(view_name, content_type)
	assert(self.app.engines.view,
		"you have to import a view engine before rendering any page")
	error "not yet implemented"
end

function fly_ticket:render_json(data)
	return self:display("application/json", json_encode(data))
end

function fly_ticket:upgrade(protocol)
	error "not yet implemented"
end

function fly_ticket:accept(...)
	assert(self.app.engines.socket,
		"you have to import a websocket engine before")
	error "not yet implemented"
end

function fly_ticket:display(content_type, str)
	assert(type(str) == "string")
	self.res:writeHead(self.status or 200, {
		["Content-Type"] = content_type,
		["Content-Length"] = #str
	})
	self.rendered = true
	self.res:finish(str)
end

function fly_ticket:redirect_to(where)
	self.res:writeHead(302, {
		Location = where,
		["Content-Length"] = 0
	})
	self.rendered = true
	self.res:finish()
end

local fly_app = {}
local fly_app_set= {}
local fly_app_mt = { __index = fly_app }

function fly_app:handle(req, res)
	local resource, query = req.url:match "^(/[^%?]*)%??(.*)"
	resource, query = querystring.urldecode(resource), querystring.parse(query)
	local handler, args
	for _, route in pairs(self.routes) do
		if route.method == req.method then
			args = { resource:match(route.pattern) }
			if #args > 0 then
				handler = route.handler
				break
			end
		end
	end
	local data, readonly = {}, { app = self, res = res, request = req, query = query }
	local ticket = setmetatable({}, {
		__index = function(_, field)
			return readonly[field] or fly_ticket[field] or data[field]
		end,
		__newindex = function(_, field, value)
			assert(
				not fly_ticket[field] and type(readonly[field]) == "nil",
				"attempt to use reserved name")
			data[field] = value
		end
	})
	if not handler then
		data.status = 404
		handler, args = self.error[404], { resource }
	end
	local succeeded, err = pcall(handler, ticket, unpack(args))
	if not succeeded then
		res:writeHead(500, { ["Content-Type"] = "text/html" })
		res:finish(("<html><body><h1>Internal Server Error</h1><p>%s</p></body></html>"):format(err))
	end
end

function fly_app:dispatch(method, pattern, handler)
	assert(type(handler) == "function", "a handler must be a function")
	assert(type(pattern) == "string", "an url pattern must be a string")
	if pattern:sub(1, 1) ~= "/" then
		pattern = "/" .. pattern
	end
	local _pattern = ("^%s$"):format(pattern)
	self.routes[#self.routes + 1] = {
		method = method, pattern = _pattern, handler = handler }
	return #self.routes
end

function fly_app:get(...)
	return self:dispatch("GET", ...)
end

function fly_app:post(...)
	return self:dispatch("POST", ...)
end

function fly_app:put(...)
	return self:dispatch("PUT", ...)
end

function fly_app:delete(...)
	return self:dispatch("DELETE", ...)
end

function fly_app:root(handler)
	return self:dispatch("GET", "/", handler)
end

function fly_app:error(status, handler)
	assert(type(status) == "number", "only status numbers accepted")
	self.error[status] = handler
end

function fly_app:use(compent)
	if type(compent) == "string" then
		compent = require(compent)
	end
	assert(type(compent) == "table", "only tables accepted")
	if compent[1] == "view engine" then
		assert(compent.compile and compent.render, "bad view engine")
		self.engines.view = compent
	else
		error "compent not accepted by this version of Fly"
	end
end

function fly_app:fly(port, ...)
	return self.server:listen(port or 8080, ...)
end

function fly_app_mt:__newindex(field, value)
	assert(not fly_app[field], "not an option")
	self.options[field] = value
end

local fly = {}

function fly.default_404(self)
	self:display("text/html", [[<html>
<head><title>Not Found</title></head>
<body>
	<h1>404 Not Found</h1>
	<p>This URI was not dispatched correctly.</p>
</body></html>]])
end

function fly.new()
	local app = {
		routes = {}, engines = {}, views = {},
		options = {
			view_dir = "views"
		},
		error = setmetatable({
			[404] = fly.default_404
		}, { __call = fly_app.error })
	}
	app.server = http.createServer(function(req, res)
		return app:handle(req, res)
	end)
	return setmetatable(app, fly_app_mt)
end

return fly
