local LuvSocks = require("../LuvSocks")

local server = LuvSocks.new():listen(1337)
print("LuvSocks server running on port 1337")


server:on("connect", function(client)
	client:on("pong", function(data)
		print("Pong received:", data)
	end)

	client:send("ping", "Hello there!")
	print("Ping sent: Hello there!")
end)