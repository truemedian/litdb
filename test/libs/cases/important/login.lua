require("wrapper")(function(test, transfromage, client, clientId)
	clientId = clientId * 2

	test("login", function(expect)
		args[clientId] = string.toNickname(args[clientId], true)

		client:once("ready", expect(function(onlinePlayers, country, language)
			p("Received event ready")

			assert(onlinePlayers)

			assert(country)
			assert_neq(country, '', "country")

			assert(language)
			assert_neq(language, '', "language")

			client:connect(args[clientId], args[clientId+1], "*transfromage")
		end))

		client:once("mainConnection", expect(function(playerId, playerName, playedTime)
			p("Received event mainConnection")

			assert(playerId)

			assert(playerName)
			assert_neq(playerName, '', "playerName")

			assert(playedTime)

			assert_eq(playerName, args[clientId], "playerName")
		end))

		client:once("connection", expect(function()
			p("Received event connection")
		end))

		p("Starting client", args[clientId])
		client:start()
	end)

	test("handle players", function(expect)
		client:handlePlayers(false)
		assert(not client._handlePlayers)

		client:handlePlayers()
		assert(client._handlePlayers)

		client:handlePlayers()
		assert(not client._handlePlayers)

		client:handlePlayers(true)
		assert(client._handlePlayers)
	end)

	test("skip first room change", function(expect)
		client:on("roomChanged", expect(function(room)
			p("Received event roomChanged")

			assert(room.name)
			assert(room.isOfficial ~= nil)
			assert(room.language)
		end))
	end)
end)