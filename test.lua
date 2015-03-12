app = require "./fly"

-- Use fly.inside as the view engine
app:use("./fly.inside")

-- Select an static directory
app.public = "public"

-- Select an directory for views
app.views = "views"

-- Render a view
app:root(function(ticket)
	ticket:render("hello.html")
end)

-- Render an JSON
app:get("/json", function(ticket)
	ticket:render_json{
		Hello = "World",
		query = ticket.query
	}
end)

-- Render an JSON, but also reply 404
app:get("/error", function(ticket)
	ticket.status = 404
	ticket:render_json{
		"Not Found", "\\\\\\" }
end)

-- Let it fly
app:fly()
