local connection = require("connection")
local byteArray = require("bArray")
local encode = require("encode")
local http = require("coro-http")
local json = require("json")
local timer = require("timer")
local enum = require("enum")
local event = require("core").Emitter
local zlibDecompress = require("miniz").inflate

local parsePacket, receive, sendHeartbeat, getKeys, closeAll
local tribulleListener, oldPacketListener, packetListener
local handlePlayerField

local client = table.setNewClass()
client.__index = client

--[[@
	@desc Creates a new instance of Client. Alias: `client()`.
	@returns client The new Client object.
	@struct {
		playerName = "", -- The nickname of the account that is attached to this instance, if there's any.
		community = 0, -- The community enum where the object is set to perform the login. Default value is EN.
		main = { }, -- The main connection object, handles the game server.
		bulle = { }, -- The bulle connection object, handles the room server.
		event = { }, -- The event emitter object, used to trigger events.
		cafe = { }, -- The cached Café structure. (topics and messages)
		playerList = { }, -- The room players data.
		-- The fields below must not be edited, since they are used internally in the api.
		_mainLoop = { }, -- (userdata) A timer that retrieves the packets received from the game server.
		_bulleLoop = { }, -- (userdata) A timer that retrieves the packets received from the room server.
		_receivedAuthkey = 0, -- Authorization key, used to connect the account.
		_gameVersion = 0, -- The game version, used to connect the account.
		_gameConnectionKey = "", -- The game connection key, used to connect the account.
		_gameIdentificationKeys = { }, -- The game identification keys, used to connect the account.
		_gameMsgKeys = { }, -- The game message keys, used to connect the account.
		_connectionTime = 0, -- The timestamp of when the player logged in. It will be 0 if the account is not connected.
		_isConnected = false, -- Whether the player is connected or not.
		_hbTimer = { }, -- (userdata) A timer that sends heartbeats to the server.
		_who_fingerprint = 0, -- A fingerprint to identify the chat where the command /who was used.
		_who_list = { }, -- A list of chat names associated to their own fingerprints.
		_process_xml = true, -- Whether the event "newGame" should decode the XML packet or not. (Set as false to save process)
		_cafeCachedMessages = { }, -- A set of message IDs to cache the read messages at the Café.
		_handle_players = false -- Whether the player-related events should be handled or not. (Set as false to save process)
	}
]]
client.new = function(self)
	local eventEmitter = event:new()

	return setmetatable({
		playerName = nil,
		community = enum.community.en,
		main = connection:new("main", eventEmitter),
		bulle = nil,
		event = eventEmitter,
		cafe = { },
		playerList = setmetatable({ }, {
			__len = function(this)
				return this.count or -1
			end
		}),
		-- Private
		_mainLoop = nil,
		_bulleLoop = nil,
		_receivedAuthkey = 0,
		_gameVersion = 0,
		_gameConnectionKey = "",
		_gameAuthkey = 0,
		_gameIdentificationKeys = { },
		_gameMsgKeys = { },
		_connectionTime = 0,
		_isConnected = false,
		_hbTimer = nil,
		_who_fingerprint = 0,
		_who_list = { },
		_process_xml = true,
		_cafeCachedMessages = { },
		_handle_players = false
	}, self)
end

-- Receive
-- Tribulle functions
tribulleListener = {
	[32] = function(self, packet, connection, tribulleId) -- Friend connected
		local playerName = packet:readUTF()
		--[[@
			@desc Triggered when a friend connects to the game.
			@param playerName<string> The player name.
		]]
		self.event:emit("friendConnection", string.toNickname(playerName, true))
	end,
	[33] = function(self, packet, connection, tribulleId) -- Friend disconnected
		local playerName = packet:readUTF()
		--[[@
			@desc Triggered when a friend disconnects from the game.
			@param playerName<string> The player name.
		]]
		self.event:emit("friendDisconnection", string.toNickname(playerName, true))
	end,
	[59] = function(self, packet, connection, tribulleId) -- /who
		local fingerprint = packet:read32()

		packet:read8() -- ?

		local total = packet:read16()
		local data = { }
		for i = 1, total do
			data[i] = string.toNickname(packet:readUTF(), true)
		end

		local chatName = self._who_list[fingerprint]
		--[[@
			@desc Triggered when the /who command is loaded in a chat.
			@param chatName<string> The name of the chat.
			@param data<table> An array with the nicknames of the current users in the chat.
		]]
		self.event:emit("chatWho", chatName, data)
		self._who_list[fingerprint] = nil
	end,
	[64] = function(self, packet, connection, tribulleId) -- #Chat Message
		local playerName, community, chatName, message = packet:readUTF(), packet:read32(), packet:readUTF(), packet:readUTF()
		--[[@
			@desc Triggered when a #chat receives a new message.
			@param chatName<string> The name of the chat.
			@param playerName<string> The player who sent the message.
			@param message<string> The message.
			@param playerCommunity<int> The community id of @playerName.
		]]
		self.event:emit("chatMessage", chatName, string.toNickname(playerName, true), string.fixEntity(message), community)
	end,
	[65] = function(self, packet, connection, tribulleId) -- Tribe message
		local memberName, message = packet:readUTF(), packet:readUTF()
		--[[@
			@desc Triggered when the tribe chat receives a new message.
			@param memberName<string> The member who sent the message.
			@param message<string> The message.
		]]
		self.event:emit("tribeMessage", string.toNickname(memberName, true), string.fixEntity(message))
	end,
	[66] = function(self, packet, connection, tribulleId) -- Whisper message
		local playerName, community, _, message = packet:readUTF(), packet:read32(), packet:readUTF(), packet:readUTF()
		--[[@
			@desc Triggered when the player receives a whisper.
			playerName<string> Who sent the whisper message.
			message<string> The message.
			playerCommunity<int> The community id of @playerName.
		]]
		self.event:emit("whisperMessage", string.toNickname(playerName, true), string.fixEntity(message), community)
	end,
	[88] = function(self, packet, connection, tribulleId) -- Tribe member connected
		local memberName = packet:readUTF()
		--[[@
			@desc Triggered when a tribe member connects to the game.
			@param memberName<string> The member name.
		]]
		self.event:emit("tribeMemberConnection", string.toNickname(memberName, true))
	end,
	[90] = function(self, packet, connection, tribulleId) -- Tribe member disconnected
		local memberName = packet:readUTF()
		--[[@
			@desc Triggered when a tribe member disconnects to the game.
			@param memberName<string> The member name.
		]]
		self.event:emit("tribeMemberDisconnection", string.toNickname(memberName, true))
	end,
	[91] = function(self, packet, connection, tribulleId) -- New tribe member
		local memberName = packet:readUTF()
		--[[@
			@desc Triggered when a player joins the tribe.
			@param memberName<string> The member who joined the tribe.
		]]
		self.event:emit("newTribeMember", string.toNickname(memberName, true))
	end,
	[92] = function(self, packet, connection, tribulleId) -- Tribe member leave
		local memberName = packet:readUTF()
		--[[@
			@desc Triggered when a member leaves the tribe.
			@param memberName<string> The member who left the tribe.
		]]
		self.event:emit("tribeMemberLeave", string.toNickname(memberName, true))
	end,
	[93] = function(self, packet, connection, tribulleId) -- Tribe member kicked
		local memberName, kickerName = packet:readUTF(), packet:readUTF()
		--[[@
			@desc Triggered when a tribe member is kicked.
			@param memberName<string> The member name.
			@param kickerName<string> The name of who kicked the member.
		]]
		self.event:emit("tribeMemberKick", string.toNickname(memberName, true), string.toNickname(kickerName, true))
	end,
	[124] = function(self, packet, connection, tribulleId) -- Tribe member kicked
		local setterName, memberName, role = packet:readUTF(), packet:readUTF(), packet:readUTF()
		--[[@
			@desc Triggered when a tribe member gets a role.
			@param memberName<string> The member name.
			@param setterName<string> The name of who set the role to the member.
			@param role<string> The role name.
		]]
		self.event:emit("tribeMemberGetRole", string.toNickname(memberName, true), string.toNickname(setterName, true), role)
	end
}
-- Old packet functions
oldPacketListener = {
	[8] = {
		[5] = function(self, data, connection, oldIdentifiers) -- Updates player dead state [true]
			if not self._handle_players or self.playerList.count == 0 then return end

			local playerId, score = data[1], data[2]
			if self.playerList[playerId] then
				self.playerList[playerId].isDead = true
				self.playerList[playerId].score = score

				--[[@
					@desc Triggered when a player dies.
					@param playerData<table> The data of the player.
					@struct @playerData {
						playerName = "", -- The nickname of the player.
						id = 0, -- The temporary id of the player during the section.
						isShaman = false, -- Whether the player is shaman or not.
						isDead = false, -- Whether the player is dead or not.
						score = 0, -- The current player score.
						hasCheese = false, -- Whether the player has cheese or not.
						title = 0, -- The id of the current title of the player.
						titleStars = 0, -- The quantity of starts that the current title of the player has.
						gender = 0, -- The gender of the player. Enum in enum.gender.
						look = "", -- The current outfit string code of the player.
						mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
						shamanColor = 0, -- The color of the player as shaman.
						nameColor = 0, -- The color of the nickname of the player.
						isSouris = false, -- Whether the player is souris or not.
						isVampire = false, -- Whether the player is vampire or not.
						hasWon = false, -- Whether the player has joined the hole in the round or not.
						winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
						winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
						isFacingRight = false, -- Whether the player is facing right or not.
						movingRight = false, -- Whether the player is moving right or not.
						movingLeft = false, -- Whether the player is moving left or not.
						isBlueShaman = false, -- Whether the player is the blue shamamn or not.
						isPinkShaman = false, -- Whether the player is the pink shamamn or not.
						x = 0, -- The coordinate X of the player in the map.
						y =  0, -- The coordinate Y of the player in the map.
						vx = 0, -- The X speed of the player in the map.
						vy =  0, -- The Y speed of the player in the map.
						isDucking = false, -- Whether the player is ducking or not.
						isJumping = false, -- Whether the player is jumping or not.
						_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
					}
				]]
				self.event:emit("playerDied", self.playerList[playerId])
			end			
		end,
		[7] = function(self, data, connection, oldIdentifiers) -- Removes player
			if not self._handle_players or self.playerList.count == 0 then return end

			local playerId = tonumber(data[1])
			if self.playerList[playerId] then
				--[[@
					@desc Triggered when a player leaves the room.
					@param playerData<table> The data of the player.
					@struct @playerData {
						playerName = "", -- The nickname of the player.
						id = 0, -- The temporary id of the player during the section.
						isShaman = false, -- Whether the player is shaman or not.
						isDead = false, -- Whether the player is dead or not.
						score = 0, -- The current player score.
						hasCheese = false, -- Whether the player has cheese or not.
						title = 0, -- The id of the current title of the player.
						titleStars = 0, -- The quantity of starts that the current title of the player has.
						gender = 0, -- The gender of the player. Enum in enum.gender.
						look = "", -- The current outfit string code of the player.
						mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
						shamanColor = 0, -- The color of the player as shaman.
						nameColor = 0, -- The color of the nickname of the player.
						isSouris = false, -- Whether the player is souris or not.
						isVampire = false, -- Whether the player is vampire or not.
						hasWon = false, -- Whether the player has joined the hole in the round or not.
						winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
						winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
						isFacingRight = false, -- Whether the player is facing right or not.
						movingRight = false, -- Whether the player is moving right or not.
						movingLeft = false, -- Whether the player is moving left or not.
						isBlueShaman = false, -- Whether the player is the blue shamamn or not.
						isPinkShaman = false, -- Whether the player is the pink shamamn or not.
						x = 0, -- The coordinate X of the player in the map.
						y =  0, -- The coordinate Y of the player in the map.
						vx = 0, -- The X speed of the player in the map.
						vy =  0, -- The Y speed of the player in the map.
						isDucking = false, -- Whether the player is ducking or not.
						isJumping = false, -- Whether the player is jumping or not.
						_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
					}
				]]
				self.event:emit("playerLeft", self.playerList[playerId])

				-- Removes the numeric reference and decreases 1 for all the next players in the queue.
				local pos = self.playerList[playerId]._pos
				table.remove(self.playerList, self.playerList[playerId]._pos)

				self.playerList.count = self.playerList.count - 1
				for i = pos, self.playerList.count do
					self.playerList[i]._pos = self.playerList[i]._pos - 1
				end

				-- Removes the other references
				self.playerList[self.playerList[playerId].playerName] = nil
				self.playerList[playerId] = nil
			end
		end
	}
}
-- Normal functions
packetListener = {
	[1] = {
		[1] = function(self, packet, connection, identifiers) -- Old packets format
			local data = string.split(packet:readUTF(), "[^\x01]+")
			local oldIdentifiers = { string.byte(table.remove(data, 1), 1, 2) }

			if oldPacketListener[oldIdentifiers[1]] and oldPacketListener[oldIdentifiers[1]][oldIdentifiers[2]] then
				return oldPacketListener[oldIdentifiers[1]][oldIdentifiers[2]](self, data, connection, oldIdentifiers)
			end

			--[[@
				@desc Triggered when an old packet is not handled by the old packet parser.
				@param oldIdentifiers<table> The oldC, oldCC identifiers that were not handled.
				@param data<table> The data that was not handled.
				@param connection<connection> The connection object.
			]]
			self.event:emit("missedOldPacket", oldIdentifiers, data, connection)
		end
	},
	[4] = {
		[4] = function(self, packet, connection, identifiers) -- Update player movement
			if not self._handle_players or self.playerList.count == 0 then return end

			local playerId = packet:read32()
			if self.playerList[playerId] then
				packet:read32() -- round code

				local oldPlayerData = table.copy(self.playerList[playerId])

				-- It's intended that, based on Lua behavior, all the hashes get updated automatically.
				self.playerList[playerId].movingRight = packet:readBool()
				self.playerList[playerId].movingLeft = packet:readBool()

				self.playerList[playerId].x = math.normalizePoint(packet:read32())
				self.playerList[playerId].y = math.normalizePoint(packet:read32())
				self.playerList[playerId].vx = packet:read16()
				self.playerList[playerId].vy = packet:read16()

				self.playerList[playerId].isJumping = packet:readBool()

				self.event:emit("updatePlayer", self.playerList[playerId], oldPlayerData)
			end
		end,
		[6] = function(self, packet, connection, identifiers) -- Updates player direction
			handlePlayerField(self, packet, "isFacingRight")
		end,
		[9] = function(self, packet, connection, identifiers) -- Updates ducking
			handlePlayerField(self, packet, "isDucking")
		end,
		[10] = function(self, packet, connection, identifiers) -- Updates player direction
			handlePlayerField(self, packet, "isFacingRight")
		end
	},
	[5] = {
		[2] = function(self, packet, connection, identifiers) -- New game
			if not self._isConnected then return end

			local map = { }
			map.code = packet:read32()

			packet:read16() -- ?
			packet:read8() -- ?
			packet:read16() -- ?

			local xml = packet:read8(packet:read16())
			if self._process_xml then
				xml = table.writeBytes(xml)
				if xml ~= '' then
					map.xml = zlibDecompress(xml, 1)
				end
			end
			map.author = packet:readUTF()
			map.perm = packet:read8()
			map.isMirrored = packet:readBool()

			--[[@
				@desc Triggered when a new map is loaded.
				@desc /!\ This event may increase the memory consumption significantly due to the XML processes. Set the variable `_process_xml` as false to avoid processing it.
				@param map<table> The new map data.
				@struct @map {
					code = 0, -- The map code.
					xml = "", -- The map XML. May be nil if the map is Vanilla.
					author = "", -- The map author
					perm = 0, -- The perm code of the map.
					isMirrored = false -- Whether the map is mirrored or not.
				}
			]]
			self.event:emit("newGame", map)
		end,
		[21] = function(self, packet, connection, identifiers) -- Room changed
			local isPrivate, roomName = packet:readBool(), packet:readUTF()

			if string.byte(roomName, 2) == 3 then
				--[[@
					@desc Triggered when the player joins a tribe house.
					@param tribeName<string> The name of the tribe.
				]]
				self.event:emit("joinTribeHouse", string.sub(roomName, 3))
			else
				--[[@
					@desc Triggered when the player changes the room.
					@param roomName<string> The name of the room.
					@param isPrivateRoom<boolean> Whether the room is only accessible by the account or not.
				]]
				self.event:emit("roomChanged", string.fixEntity(roomName), isPrivate)
			end
		end
	},
	[6] = {
		[6] = function(self, packet, connection, identifiers) -- Room message
			local playerId, playerName, playerCommu, message = packet:read32(), packet:readUTF(), packet:read8(), string.fixEntity(packet:readUTF())
			--[[@
				@desc Triggered when the room receives a new user message.
				@param playerName<string> The player who sent the message.
				@param message<string> The message.
				@param playerCommunity<int> The community id of @playerName.
				@param playerId<int> The temporary id of @playerName.
			]]
			self.event:emit("roomMessage", string.toNickname(playerName, true), string.fixEntity(message), playerCommu, playerId)
		end,
		[20] = function(self, packet, connection, identifiers) -- /time
			packet:read8() -- ?
			packet:readUTF() -- $TempsDeJeu
			packet:read8() -- Total parameters (useless?)

			local time = { }
			time.day = tonumber(packet:readUTF())
			time.hour = tonumber(packet:readUTF())
			time.minute = tonumber(packet:readUTF())
			time.second = tonumber(packet:readUTF())

			--[[@
				@desc Triggered when the command /time is requested.
				@param time<table> The account's time data.
				@struct @param {
					day = 0, -- Total days
					hour = 0, -- Total hours
					minute = 0, -- Total minutes
					second = 0 -- Total seconds
				}
			]]
			self.event:emit("time", time)
		end
	},
	[8] = {
		[6] = function(self, packet, connection, identifiers) -- Updates player win state
			if not self._handle_players or self.playerList.count == 0 then return end

			packet:readBool() -- ?

			local playerId = packet:read32()
			if self.playerList[playerId] then
				self.playerList[playerId].score = packet:read16()
				self.playerList[playerId].hasWon = true
				self.playerList[playerId].winPosition = packet:read8()
				self.playerList[playerId].winTimeElapsed = packet:read16() / 100

				--[[@
					@desc Triggered when a player joins the hole.
					@param playerData<table> The data of the player.
					@param position<int> The position where the player joined the hole.
					@param timeElapsed<number> The time elapsed when the accont joined the hole.
					@struct @playerdata {
						playerName = "", -- The nickname of the player.
						id = 0, -- The temporary id of the player during the section.
						isShaman = false, -- Whether the player is shaman or not.
						isDead = false, -- Whether the player is dead or not.
						score = 0, -- The current player score.
						hasCheese = false, -- Whether the player has cheese or not.
						title = 0, -- The id of the current title of the player.
						titleStars = 0, -- The quantity of starts that the current title of the player has.
						gender = 0, -- The gender of the player. Enum in enum.gender.
						look = "", -- The current outfit string code of the player.
						mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
						shamanColor = 0, -- The color of the player as shaman.
						nameColor = 0, -- The color of the nickname of the player.
						isSouris = false, -- Whether the player is souris or not.
						isVampire = false, -- Whether the player is vampire or not.
						hasWon = false, -- Whether the player has joined the hole in the round or not.
						winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
						winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
						isFacingRight = false, -- Whether the player is facing right or not.
						movingRight = false, -- Whether the player is moving right or not.
						movingLeft = false, -- Whether the player is moving left or not.
						isBlueShaman = false, -- Whether the player is the blue shamamn or not.
						isPinkShaman = false, -- Whether the player is the pink shamamn or not.
						x = 0, -- The coordinate X of the player in the map.
						y =  0, -- The coordinate Y of the player in the map.
						vx = 0, -- The X speed of the player in the map.
						vy =  0, -- The Y speed of the player in the map.
						isDucking = false, -- Whether the player is ducking or not.
						isJumping = false, -- Whether the player is jumping or not.
						_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
					}
				]]
				self.event:emit("playerWon", self.playerList[playerId], self.playerList[playerId].winPosition, self.playerList[playerId].winTimeElapsed)
			end
		end,
		[7] = function(self, packet, connection, identifiers) -- Updates player score
			handlePlayerField(self, packet, "score", nil, "read16")
		end,
		[11] = function(self, packet, connection, identifiers) -- Updates blue/ping shaman
			if not self._handle_players or self.playerList.count == 0 then return end

			local shaman = { }
			shaman[1] = packet:read32() -- Blue
			shaman[2] = packet:read32() -- Pink

			local oldPlayerData
			for i = 1, 2 do
				if self.playerList[shaman[i]] then
					oldPlayerData = table.copy(self.playerList[shaman[i]])

					self.playerList[shaman[i]][(i == 1 and "isBlueShaman" or "isPinkShaman")] = true

					self.event:emit("updatePlayer", self.playerList[shaman[i]], oldPlayerData)
				end
			end
		end,
		[12] = function(self, packet, connection, identifiers) -- Updates player shaman state [true]
			handlePlayerField(self, packet, "isShaman", nil, nil, true)
		end,
		[16] = function(self, packet, connection, identifiers) -- Profile data
			local data = { }
			data.playerName = packet:readUTF()
			data.id = packet:read32()
			data.registrationDate = packet:read32()
			data.role = packet:read8() -- enum.role

			data.gender = packet:read8() -- enum.gender
			data.tribeName = packet:readUTF()
			data.soulmate = packet:readUTF()

			data.saves = { }
			data.saves.normal = packet:read32()
			data.shamanCheese = packet:read32()
			data.firsts = packet:read32()
			data.cheeses = packet:read32()
			data.saves.hard = packet:read32()
			data.bootcamps = packet:read32()
			data.saves.divine = packet:read32()

			data.titleId = packet:read16()
			data.totalTitles = packet:read16()
			data.titles = { }
			for i = 1, data.totalTitles do
				data.titles[packet:read16()] = packet:read8() -- id, stars
			end

			data.look = packet:readUTF()

			data.level = packet:read16()

			data.totalBadges = packet:read16() / 2
			data.badges = { }
			for i = 1, data.totalBadges do
				data.badges[packet:read16()] = packet:read16() -- id, quantity
			end

			data.totalModeStats = packet:read8()
			data.modeStats = { }
			local modeId
			for i = 1, data.totalModeStats do
				modeId = packet:read8()
				data.modeStats[modeId] = { }
				data.modeStats[modeId].progress = packet:read32()
				data.modeStats[modeId].progressLimit = packet:read32()
				data.modeStats[modeId].imageId = packet:read8()
			end

			data.orbId = packet:read8()
			data.totalOrbs = packet:read8()
			data.orbs = { }
			for i = 1, data.totalOrbs do
				data.orbs[packet:read8()] = true
			end

			packet:read8() -- ?

			data.adventurePoints = packet:read32()

			--[[@
				@desc Triggered when the profile of an player is loaded.
				@param data<table> The player profile data.
				@struct @data {
					playerName = "", -- The player name.
					id = 0, -- The player id.
					registrationDate = 0, -- The timestamp of when the player was created.
					role = 0, -- An enum from enum.role that specifies the player's role.
					gender = 0, -- An enum from enum.gender for the player's gender. 
					tribeName = "", -- The name of the tribe.
					soulmate = "", -- The name of the soulmate.
					saves = {
						normal = 0, -- Total saves in the normal mode.
						hard = 0, -- Total saves in the hard mode.
						divine = 0 -- Total saves in the divine mode.
					}, -- Total saves of the player.
					shamanCheese = 0, -- Total of cheeses gathered as shaman.
					firsts = 0, -- Total of firsts.
					cheeses = 0, -- Total of cheeses.
					bootcamps = 0, -- Total of bootcamps.
					titleId = 0, -- The id of the current title.
					totalTitles = 0, -- Total of unlocked titles.
					titles = {
						[id] = 0 -- The id of the title as index, the quantity of stars as value.
					}, -- The list of unlocked titles.
					look = "", -- The player's outfit code.
					level = 0, -- The player's level.
					totalBadges = 0, -- The total of unlocked badges.
					badges = {
						[id] = 0 -- The id of the badge as index, the quantity as value.
					}, -- The list of unlocked badges.
					totalModeStats = 0, -- The total of mode statuses.
					modeStats = {
						[id] = {
							progress = 0, -- The current score in the status.
							progressLimit = 0, -- The status score limit.
							imageId = 0 -- The image id of the status. 
						} -- The status id.
					}, -- The list of mode statuses.
					orbId = 0, -- The id of the current shaman orb.
					totalOrbs = 0, -- The total of unlocked shaman orbs.
					orbs = {
						[id] = true -- The id of the shaman orb as index.
					}, -- The list of unlocked shaman orbs.
					adventurePoints = 0 -- The total adventure points.
				}
			]]
			self.event:emit("profileLoaded", data)
		end,
		[66] = function(self, packet, connection, identifiers) -- Updates player vampire state
			--[[@
				@desc Triggered when a player is transformed from/into a vampire.
				@param playerData<table> The data of the player.
				@param isVampire<boolean> Whether the player is a vampire or not.
				@struct @playerdata {
					playerName = "", -- The nickname of the player.
					id = 0, -- The temporary id of the player during the section.
					isShaman = false, -- Whether the player is shaman or not.
					isDead = false, -- Whether the player is dead or not.
					score = 0, -- The current player score.
					hasCheese = false, -- Whether the player has cheese or not.
					title = 0, -- The id of the current title of the player.
					titleStars = 0, -- The quantity of starts that the current title of the player has.
					gender = 0, -- The gender of the player. Enum in enum.gender.
					look = "", -- The current outfit string code of the player.
					mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
					shamanColor = 0, -- The color of the player as shaman.
					nameColor = 0, -- The color of the nickname of the player.
					isSouris = false, -- Whether the player is souris or not.
					isVampire = false, -- Whether the player is vampire or not.
					hasWon = false, -- Whether the player has joined the hole in the round or not.
					winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
					winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
					isFacingRight = false, -- Whether the player is facing right or not.
					movingRight = false, -- Whether the player is moving right or not.
					movingLeft = false, -- Whether the player is moving left or not.
					isBlueShaman = false, -- Whether the player is the blue shamamn or not.
					isPinkShaman = false, -- Whether the player is the pink shamamn or not.
					x = 0, -- The coordinate X of the player in the map.
					y =  0, -- The coordinate Y of the player in the map.
					vx = 0, -- The X speed of the player in the map.
					vy =  0, -- The Y speed of the player in the map.
					isDucking = false, -- Whether the player is ducking or not.
					isJumping = false, -- Whether the player is jumping or not.
					_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
				}
			]]
			handlePlayerField(self, packet, "isVampire", "playerVampire", nil, nil, true)
		end
	},
	[26] = {
		[2] = function(self, packet, connection, identifiers) -- Set connection
			self._isConnected = true
		end,
		[3] = function(self, packet, connection, identifiers) -- Correct handshake identifiers
			local onlinePlayers = packet:read32()

			connection.packetID = packet:read8()
			local community = packet:readUTF() -- Necessary to get the country and authkeys later
			local country = packet:readUTF()

			self._receivedAuthkey = packet:read32() -- Receives an authentication key, parsed in the login function

			self._hbTimer = timer.setInterval(10 * 1000, sendHeartbeat, self)

			community = byteArray:new():write8(self.community):write8(0)
			self.main:send(enum.identifier.community, community)

			local osInfo = byteArray:new():writeUTF("en"):writeUTF("Linux")
			osInfo:writeUTF("LNX 29,0,0,140"):write8(0)
			self.main:send(enum.identifier.os, osInfo)
		end,
		[35] = function(self, packet, connection, identifiers) -- Room list
			for i = 1, packet:read8() do packet:read8() end -- Room types

			local rooms, counter = { }, 0
			local pinned, pinnedCounter = { }, 0

			local roomType, name, count, max, onFcMode
			local roomMode = packet:read8()
			while #packet.stack > 0 do
				roomType = packet:read8()
				if roomType == 0 then -- Normal room
					packet:read8() -- community
					name = packet:readUTF()
					count = packet:read16() -- total mice
					max = packet:read8() -- max total mice
					onFcMode = packet:readBool() -- funcorp mode

					counter = counter + 1
					rooms[counter] = {
						name = name,
						totalPlayers = count,
						maxPlayers = max,
						onFuncorpMode = onFcMode
					}
				elseif roomType == 1 then -- Pinned rooms / modules
					packet:read8() -- community
					name = packet:readUTF()
					count = packet:readUTF() -- total mice
					count = tonumber(count) or count -- Make it a number
					packet:readUTF() -- mjj
					packet:readUTF() -- m room/#module

					pinnedCounter = pinnedCounter + 1
					pinned[pinnedCounter] = {
						name = name,
						totalPlayers = count
					}
				end
			end

			--[[@
				@desc Triggered when the room list of a mode is loaded.
				@param roomMode<int> The id of the room mode.
				@param rooms<table> The data of the rooms in the list.
				@param pinned<tablet> The data of the pinned objects in the list.
				@struct @rooms {
					[n] = {
						name = "", -- The name of the room.
						totalPlayers = 0, -- The quantity of players in the room.
						maxPlayers = 0, -- The maximum quantity of players the room can get.
						onFuncorpMode = false -- Whether the room is having a funcorp event (orange name) or not.
					}
				}
				@struct @pinned {
					[n] = {
						name = "", -- The name of the object.
						totalPlayers = 0 -- The quantity of players in the object counter. (Might be a string)
					}
				}
			]]
			self.event:emit("roomList", roomMode, rooms, pinned)
		end,
	},
	[28] = {
		[5] = function(self, packet, connection, identifiers) -- /mod, /mapcrew
			packet:read16() -- ?
			--[[@
				@desc Triggered when a staff list is loaded (/mod, /mapcrew).
				@param list<string> The staff list content.
			]]
			self.event:emit("staffList", packet:readUTF())
		end,
		[6] = function(self, packet, connection, identifiers) -- Ping
			--[[@
				@desc Triggered when a server heartbeat is received.
				@param time<int> The current time.
			]]
			self.event:emit("ping", os.time())
		end
	},
	[29] = {
		[6] = function(self, packet, connection, identifiers) -- Lua logs
			--[[@
				@desc Triggered when the #lua chat receives a log message.
				@param log<string> The log message.
			]]
			self.event:emit("lua", packet:readUTF())
		end
	},
	[30] = {
		[40] = function(self, packet, connection, identifiers) -- Cafe topic data
			local id, data
			local _messages, _totalMessages, _author

			while #packet.stack > 0 do
				id = packet:read32()
				data = { id = id }
				data.title = packet:readUTF()
				data.authorId = packet:read32()
				data.posts = packet:read32()
				data.lastUserName = packet:readUTF()
				data.timestamp = os.time() - packet:read32()

				if self.cafe[id] then
					data.messages = self.cafe[id].messages
					data.author = self.cafe[id].author
				end
				self.cafe[id] = data
			end

			--[[@
				@desc Triggered when the Café is opened or refreshed, and the topics are loaded partially.
				@param data<table> The data of the topics.
				@struct @data
				{
					[i] = {
						id = 0, -- The id of the topic.
						title = "", -- The title of the topic.
						authorId = 0, -- The id of the topic author.
						posts = 0, -- The quantity of messages in the topic.
						lastUserName = "", -- The name of the last user that posted in the topic.
						timestamp = 0, -- When the topic was created.

						-- The event "cafeTopicLoad" must be triggered so the fields below exist.
						author = "", -- The name of the topic author.
						messages = {
							[i] = {
								topicId = 0, -- The id of the topic where the message is located.
								id = 0, -- The id of the message.
								authorId = 0, -- The id of the topic author.
								timestamp = 0, -- When the topic was created.
								author = "", -- The name of the topic author.
								content = "", -- The content of the message.
								canLike = false, -- Whether the message can be liked by the bot or not.
								likes = 0 -- The quantity of likes in the message.
							}
						}
					}
				}
			]]
			self.event:emit("cafeTopicList", self.cafe)
		end,
		[41] = function(self, packet, connection, identifiers) -- Cafe message data
			packet:read8() -- ?

			local id = packet:read32()
			if not self.cafe[id] then
				self.cafe[id] = { id = id }
			end
			local data = self.cafe[id]

			data.messages = { }

			local totalMessages = 0

			while #packet.stack > 0 do
				totalMessages = totalMessages + 1
				data.messages[totalMessages] = { }
				data.messages[totalMessages].topicId = id
				data.messages[totalMessages].id = packet:read32()
				data.messages[totalMessages].authorId = packet:read32()
				data.messages[totalMessages].timestamp = os.time() - packet:read32()
				data.messages[totalMessages].author = packet:readUTF()
				data.messages[totalMessages].content = string.gsub(packet:readUTF(), "\r", "\r\n")
				data.messages[totalMessages].canLike = packet:readBool()
				data.messages[totalMessages].likes = packet:read16()
			end

			data.author = data.messages[1].author

			--[[@
				@desc Triggered when a Café topic is opened or refreshed.
				@param topic<table> The data of the topic.
				@struct @topic
				{
					id = 0, -- The id of the topic.
					title = "", -- The title of the topic.
					authorId = 0, -- The id of the topic author.
					posts = 0, -- The quantity of messages in the topic.
					lastUserName = "", -- The name of the last user that posted in the topic.
					timestamp = 0, -- When the topic was created.
					author = "", -- The name of the topic author.
					messages = {
						[i] = {
							topicId = 0, -- The id of the topic where the message is located.
							id = 0, -- The id of the message.
							authorId = 0, -- The id of the topic author.
							timestamp = 0, -- When the topic was created.
							author = "", -- The name of the topic author.
							content = "", -- The content of the message.
							canLike = false, -- Whether the message can be liked by the bot or not.
							likes = 0 -- The quantity of likes in the message.
						}
					}
				}
			]]
			self.event:emit("cafeTopicLoad", topic)

			for i = 1, totalMessages do -- Unfortunately I couldn't make it decrescent, otherwise it would trigger the events in the wrong order
				if not self._cafeCachedMessages[data.messages[i].id] then
					self._cafeCachedMessages[data.messages[i].id] = true

					--[[@
						@desc Triggered when a new message in a Café topic is cached.
						@param message<table> The data of the message.
						@param topic<table> The data of the topic.
						@struct @message
						{
							topicId = 0, -- The id of the topic where the message is located.
							id = 0, -- The id of the message.
							authorId = 0, -- The id of the topic author.
							timestamp = 0, -- When the topic was created.
							author = "", -- The name of the topic author.
							content = "", -- The content of the message.
							canLike = false, -- Whether the message can be liked by the bot or not.
							likes = 0 -- The quantity of likes in the message.
						}
						@struct @data
						{
							id = 0, -- The id of the topic.
							title = "", -- The title of the topic.
							authorId = 0, -- The id of the topic author.
							posts = 0, -- The quantity of messages in the topic.
							lastUserName = "", -- The name of the last user that posted in the topic.
							timestamp = 0, -- When the topic was created.
							author = "", -- The name of the topic author.
							messages = {
								[i] = {
									topicId = 0, -- The id of the topic where the message is located.
									id = 0, -- The id of the message.
									authorId = 0, -- The id of the topic author.
									timestamp = 0, -- When the topic was created.
									author = "", -- The name of the topic author.
									content = "", -- The content of the message.
									canLike = false, -- Whether the message can be liked by the bot or not.
									likes = 0 -- The quantity of likes in the message.
								}
							}
						}
					]]
					self.event:emit("cafeTopicMessage", data.messages[i], data)
				end
			end
		end,
		[44] = function(self, packet, connection, identifiers) -- New Cafe post detected
			local topicId = packet:read32()

			--[[@
				@desc Triggered when new messages are posted on Café.
				@param topicId<int> The id of the topic where the new messages were posted.
				@param topic<table> The data of the topic. It **may be** nil.
				@struct @topic
				{
					id = 0, -- The id of the topic.
					title = "", -- The title of the topic.
					authorId = 0, -- The id of the topic author.
					posts = 0, -- The quantity of messages in the topic.
					lastUserName = "", -- The name of the last user that posted in the topic.
					timestamp = 0, -- When the topic was created.

					-- The event "cafeTopicLoad" must be triggered so the fields below exist.
					author = "", -- The name of the topic author.
					messages = {
						-- This might not include the unread message.
						[i] = {
							topicId = 0, -- The id of the topic where the message is located.
							id = 0, -- The id of the message.
							authorId = 0, -- The id of the topic author.
							timestamp = 0, -- When the topic was created.
							author = "", -- The name of the topic author.
							content = "", -- The content of the message.
							canLike = false, -- Whether the message can be liked by the bot or not.
							likes = 0 -- The quantity of likes in the message.
						}
					}
				}
			]]
			self.event:emit("unreadCafeMessage", topicId, self.cafe[topicId])
		end
	},
	[44] = {
		[1] = function(self, packet, connection, identifiers) -- Switch bulle identifiers
			local bulleId = packet:read32()
			local bulleIp = packet:readUTF()

			self.bulle = connection:new("bulle", self.event)
			self.bulle:connect(bulleIp, enum.setting.port[self.main.port])

			self.bulle.event:once("_socketConnection", function()
				self.bulle:send(enum.identifier.bulleConnection, byteArray:new():write32(bulleId))
			end)
		end,
		[22] = function(self, packet, connection, identifiers) -- PacketID offset identifiers
			connection.packetID = packet:read8() -- Sets the pkt of the connection
		end
	},
	[60] = {
		[3] = function(self, packet, connection, identifiers) -- Community Platform
			local tribulleId = packet:read16()
			if tribulleListener[tribulleId] then
				return tribulleListener[tribulleId](self, packet, connection, tribulleId)
			end
			--[[@
				@desc Triggered when a tribulle packet is not handled by the tribulle packet parser.
				@param tribulleId<int> The tribulle id.
				@param packet<byteArray> The Byte Array object with the packet that was not handled.
				@param connection<connection> The connection object.
			]]
			self.event:emit("missedTribulle", tribulleId, packet, connection)
		end
	},
	[144] = {
		[1] = function(self, packet, connection, identifiers) -- Set player list
			if not self._handle_players then return end

			self.playerList.count = packet:read16() -- Total mice in the room

			for i = 1, self.playerList.count do
				packetListener[144][2](self, packet, connection, nil, i)
			end

			--[[@
				@desc Triggered when the data of all players are refreshed (mostly in new games).
				@param playerList<table> The data of all players.
				@struct @playerList {
					[playerName] = {
						playerName = "", -- The nickname of the player.
						id = 0, -- The temporary id of the player during the section.
						isShaman = false, -- Whether the player is shaman or not.
						isDead = false, -- Whether the player is dead or not.
						score = 0, -- The current player score.
						hasCheese = false, -- Whether the player has cheese or not.
						title = 0, -- The id of the current title of the player.
						titleStars = 0, -- The quantity of starts that the current title of the player has.
						gender = 0, -- The gender of the player. Enum in enum.gender.
						look = "", -- The current outfit string code of the player.
						mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
						shamanColor = 0, -- The color of the player as shaman.
						nameColor = 0, -- The color of the nickname of the player.
						isSouris = false, -- Whether the player is souris or not.
						isVampire = false, -- Whether the player is vampire or not.
						hasWon = false, -- Whether the player has joined the hole in the round or not.
						winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
						winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
						isFacingRight = false, -- Whether the player is facing right or not.
						movingRight = false, -- Whether the player is moving right or not.
						movingLeft = false, -- Whether the player is moving left or not.
						isBlueShaman = false, -- Whether the player is the blue shamamn or not.
						isPinkShaman = false, -- Whether the player is the pink shamamn or not.
						x = 0, -- The coordinate X of the player in the map.
						y =  0, -- The coordinate Y of the player in the map.
						vx = 0, -- The X speed of the player in the map.
						vy =  0, -- The Y speed of the player in the map.
						isDucking = false, -- Whether the player is ducking or not.
						isJumping = false, -- Whether the player is jumping or not.
						_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
					},
					[i] = { }, -- Reference of [playerName], 'i' is stored in '_pos'
					[id] = { } -- Reference of [playerName]
				}
			]]
			self.event:emit("refreshPlayerList", self.playerList)
		end,
		[2] = function(self, packet, connection, identifiers, _pos) -- Updates player data
			if not self._handle_players or (not _pos and self.playerList.count == 0) then return end

			local data, color = { }
			data.playerName = packet:readUTF()
			data.id = packet:read32() -- Temporary id
			data.isShaman = packet:readBool()
			data.isDead = packet:readBool()
			data.score = packet:read16()
			data.hasCheese = packet:readBool()
			data.title = packet:read16()
			data.titleStars = packet:read8() - 1
			data.gender = packet:read8()
			packet:readUTF() -- ?
			data.look = packet:readUTF()
			packet:readBool() -- ?
			data.mouseColor = packet:read32()
			data.shamanColor = packet:read32()
			packet:read32() -- ?
			color = packet:read32()
			data.nameColor = (color == 0xFFFFFFFF and -1 or color)

			-- Custom or delayed data
			data.isSouris = (string.sub(data.playerName, 1, 1) == '*')
			data.isVampire = false
			data.hasWon = false
			data.winPosition = -1
			data.winTimeElapsed = -1
			data.isFacingRight = true
			data.movingRight = false
			data.movingLeft = false
			data.isBlueShaman = false
			data.isPinkShaman = false

			data.x = 0
			data.y = 0
			data.vx = 0
			data.vy = 0
			data.isDucking = false
			data.isJumping = false

			local isNew, oldPlayerData = false
			if not self.playerList[data.playerName] then
				isNew = true

				if _pos then
					data._pos = _pos
				else
					self.playerList.count = self.playerList.count + 1
					data._pos = self.playerList.count
				end
			else
				oldPlayerData = table.copy(self.playerList[data.id])
				data._pos = self.playerList[data.playerName]._pos
			end

			self.playerList[data._pos] = data
			self.playerList[data.playerName] = data
			self.playerList[data.id] = data

			if not _pos and not (isNew and data.playerName == self.playerName) then
				--[[@
					@desc Triggered when a new player joins the room.
					@param playerData<table> The data of the player.
					@struct @playerdata {
						playerName = "", -- The nickname of the player.
						id = 0, -- The temporary id of the player during the section.
						isShaman = false, -- Whether the player is shaman or not.
						isDead = false, -- Whether the player is dead or not.
						score = 0, -- The current player score.
						hasCheese = false, -- Whether the player has cheese or not.
						title = 0, -- The id of the current title of the player.
						titleStars = 0, -- The quantity of starts that the current title of the player has.
						gender = 0, -- The gender of the player. Enum in enum.gender.
						look = "", -- The current outfit string code of the player.
						mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
						shamanColor = 0, -- The color of the player as shaman.
						nameColor = 0, -- The color of the nickname of the player.
						isSouris = false, -- Whether the player is souris or not.
						isVampire = false, -- Whether the player is vampire or not.
						hasWon = false, -- Whether the player has joined the hole in the round or not.
						winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
						winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
						isFacingRight = false, -- Whether the player is facing right or not.
						movingRight = false, -- Whether the player is moving right or not.
						movingLeft = false, -- Whether the player is moving left or not.
						isBlueShaman = false, -- Whether the player is the blue shamamn or not.
						isPinkShaman = false, -- Whether the player is the pink shamamn or not.
						x = 0, -- The coordinate X of the player in the map.
						y =  0, -- The coordinate Y of the player in the map.
						vx = 0, -- The X speed of the player in the map.
						vy =  0, -- The Y speed of the player in the map.
						isDucking = false, -- Whether the player is ducking or not.
						isJumping = false, -- Whether the player is jumping or not.
						_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
					}
				]]
				self.event:emit((isNew and "newPlayer" or "updatePlayer"), data, oldPlayerData)
			end
		end,
		[6] = function(self, packet, connection, identifiers) -- Updates player cheese state
			--[[@
				@desc Triggered when a player gets (or loses) a cheese.
				@param playerData<table> The data of the player.
				@param hasCheese<boolean> Whether the player has cheese or not.
				@struct @playerdata {
					playerName = "", -- The nickname of the player.
					id = 0, -- The temporary id of the player during the section.
					isShaman = false, -- Whether the player is shaman or not.
					isDead = false, -- Whether the player is dead or not.
					score = 0, -- The current player score.
					hasCheese = false, -- Whether the player has cheese or not.
					title = 0, -- The id of the current title of the player.
					titleStars = 0, -- The quantity of starts that the current title of the player has.
					gender = 0, -- The gender of the player. Enum in enum.gender.
					look = "", -- The current outfit string code of the player.
					mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
					shamanColor = 0, -- The color of the player as shaman.
					nameColor = 0, -- The color of the nickname of the player.
					isSouris = false, -- Whether the player is souris or not.
					isVampire = false, -- Whether the player is vampire or not.
					hasWon = false, -- Whether the player has joined the hole in the round or not.
					winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
					winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
					isFacingRight = false, -- Whether the player is facing right or not.
					movingRight = false, -- Whether the player is moving right or not.
					movingLeft = false, -- Whether the player is moving left or not.
					isBlueShaman = false, -- Whether the player is the blue shamamn or not.
					isPinkShaman = false, -- Whether the player is the pink shamamn or not.
					x = 0, -- The coordinate X of the player in the map.
					y =  0, -- The coordinate Y of the player in the map.
					vx = 0, -- The X speed of the player in the map.
					vy =  0, -- The Y speed of the player in the map.
					isDucking = false, -- Whether the player is ducking or not.
					isJumping = false, -- Whether the player is jumping or not.
					_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
				}
			]]
			handlePlayerField(self, packet, "hasCheese", "playerGetCheese", nil, nil, true)
		end,
		[7] = function(self, packet, connection, identifiers) -- Updates player shaman state [false]
			handlePlayerField(self, packet, "isShaman", nil, nil, false)
		end
	}
}

-- System
-- Packet listeners and parsers
--[[@
	@desc Inserts a new function to the packet parser.
	@param C<int> The C packet.
	@param CC<int> The CC packet.
	@param f<function> The function to be triggered when the @C-@CC packets are received. The parameters are (packet, connection, identifiers).
	@param append?<boolean> True if the function should be appended to the (C, CC) listener, false if the function should overwrite the (C, CC) listener. @default false
]]
client.insertPacketListener = function(self, C, CC, f, append)
	if not packetListener[C] then
		packetListener[C] = { }
	end

	f = coroutine.makef(f)
	if append and packetListener[C][CC] then
		packetListener[C][CC] = function(...)
			packetListener[C][CC](...)
			f(...)
		end
	else
		packetListener[C][CC] = f
	end
end
--[[@
	@desc Inserts a new function to the tribulle (60, 3) packet parser.
	@param tribulleId<int> The tribulle id.
	@param f<function> The function to be triggered when this tribulle packet is received. The parameters are (packet, connection, tribulleId).
	@param append?<boolean> True if the function should be appended to the (C, CC, tribulle) listener, false if the function should overwrite the (C, CC) listener. @default false
]]
client.insertTribulleListener = function(self, tribulleId, f, append)
	f = coroutine.makef(f)
	if append and tribulleListener[tribulleId] then
		tribulleListener[tribulleId] = function(...)
			tribulleListener[tribulleId](...)
			f(...)
		end
	else
		tribulleListener[tribulleId] = f
	end
end
--[[@
	@desc Inserts a new function to the old packet parser.
	@param C<int> The C packet.
	@param CC<int> The CC packet.
	@param f<function> The function to be triggered when the @C-@CC packets are received. The parameters are (data, connection, oldIdentifiers).
	@param append?<boolean> True if the function should be appended to the (C, CC) listener, false if the function should overwrite the (C, CC) listener. @default false
]]
client.insertOldPacketListener = function(self, C, CC, f, append)
	if not oldPacketListener[C] then
		oldPacketListener[C] = { }
	end

	f = coroutine.makef(f)
	if append and oldPacketListener[C][CC] then
		oldPacketListener[C][CC] = function(...)
			oldPacketListener[C][CC](...)
			f(...)
		end
	else
		oldPacketListener[C][CC] = f
	end
end

----- Compatibility -----
client.insertReceiveFunction, client.insertTribulleFunction = client.insertPacketListener, client.insertTribulleListener
-------------------------

--[[@
	@desc Handles the received packets by triggering their listeners.
	@param self<client> A Client object.
	@param connection<connection> A Connection object attached to @self.
	@param packet<byteArray> THe packet to be parsed.
]]
parsePacket = function(self, connection, packet)
	local C, CC = packet:read8(), packet:read8()
	local identifiers = { C, CC }

	if packetListener[C] and packetListener[C][CC] then
		return packetListener[C][CC](self, packet, connection, identifiers)
	end
	--[[@
		@desc Triggered when an identifier is not handled by the system.
		@param identifiers<table> The C, CC identifiers that were not handled.
		@param packet<byteArray> The Byte Array object with the packet that was not handled.
		@param connection<connection> The connection object.
	]]
	self.event:emit("missedPacket", identifiers, packet, connection)
end
--[[@
	@desc Creates a new timer attached to a connection object to receive packets and parse them.
	@param self<client> A Client object.
	@param connectionName<string> The name of the Connection object to get the timer attached to.
]]
receive = function(self, connectionName)
	self["_" .. connectionName .. "Loop"] = timer.setInterval(10, function(self)
		if self[connectionName] and self[connectionName].open then
			local packet = self[connectionName]:receive()
			if not packet then return end

			self.event:emit("_receive", self[connectionName], byteArray:new(packet))
			parsePacket(self, self[connectionName], byteArray:new(packet))
		end
	end, self)
end
--[[@
	@desc Gets the connection keys in the API endpoint.
	@desc This function is destroyed when @see client.start is called.
	@param self<client> A Client object.
	@param tfmId<string,int> The developer's transformice id.
	@param token<string> The developer's token.
]]
getKeys = function(self, tfmId, token)
	local _, result = http.request("GET", "https://api.tocu.tk/get_transformice_keys.php?tfmid=" .. tfmId .. "&token=" .. token, {
		{ "User-Agent", "Mozilla/5.0" }
	})
	local _r = result
	result = json.decode(result)
	if not result then
		return error("↑error↓[API ENDPOINT]↑ ↑highlight↓TFMID↑ or ↑highlight↓TOKEN↑ value is invalid.\n\t" .. tostring(_r), enum.errorLevel.high)
	end

	if result.success then
		if not result.internal_error then
			self._gameVersion = result.version
			self._gameConnectionKey = result.connection_key
			self._gameAuthkey = result.auth_key
			self._gameIdentificationKeys = result.identification_keys
			self._gameMsgKeys = result.msg_keys

			encode.setPacketKeys(self._gameIdentificationKeys, self._gameMsgKeys)
		else
			return error("↑error↓[API ENDPOINT]↑ An internal error occurred in the API endpoint.\n\t'" .. result.internal_error_step .. "'" .. ((result.internal_error_step == 2) and ": The game may be in maintenance." or ''), enum.errorLevel.high)
		end
	else
		return error("↑error↓[API ENDPOINT]↑ Impossible to get the keys.\n\tError: " .. tostring(result.error), enum.errorLevel.high)
	end
end
--[[@
	@desc Sends server heartbeats/pings to the servers.
	@param self<client> A Client object.
]]
sendHeartbeat = function(self)
	self.main:send(enum.identifier.heartbeat, byteArray:new())
	if self.bulle and self.bulle.open then
		self.bulle:send(enum.identifier.heartbeat, byteArray:new())
	end

	--[[@
		@desc Triggered when a heartbeat is sent to the connection, every 10 seconds.
		@param time<int> The current time.
	]]
	self.event:emit("heartbeat", os.time())
end
--[[@
	@desc Closes all the Connection objects.
	@desc Note that a new Client instance should be created instead of closing and re-opening an existent one.
	@param self<client> A Client object.
]]
closeAll = function(self)
	if self.main then
		if self.bulle then
			timer.clearInterval(self._bulleLoop)
			self.bulle:close()
		end
		timer.clearInterval(self._mainLoop)
		self.main:close()
	end
end
--[[@
	@desc Handles the packets that alters only one player data field.
	@param self<client> A Client object.
	@param packet<byteArray> A Byte Array object with the data to be extracted.
	@param fieldName<string> THe name of the field to be altered.
	@param eventName?<string> The name of the event to be triggered. @default "updatePlayer"
	@param methodName?<string> The name of the ByteArray function to be used to extract the data from @packet. @default "readBool"
	@param fieldValue?<*> The value to be set to the player data @fieldName. @default Extracted data
	@param sendValue?<boolean> Whether the new value should be sent as second argument of the event or not. @default false
]]
handlePlayerField = function(self, packet, fieldName, eventName, methodName, fieldValue, sendValue) -- It would be a table with settings, but since it's created many times I have decided to keep it as parameters.
	if not self._handle_players or self.playerList.count == 0 then return end

	local playerId = packet:read32()
	if self.playerList[playerId] then
		if fieldValue == nil then
			fieldValue = packet[(methodName or "readBool")](packet)
		end

		local oldPlayerData
		if not eventName then -- updatePlayer
			oldPlayerData = table.copy(self.playerList[playerId])
		end

		self.playerList[playerId][fieldName] = fieldValue

		--[[@
			@desc Triggered when a player field is updated.
			@param playerData<table> The data of the player.
			@param oldPlayerData<table> The data of the player before the new values.
			@struct @playerdata @oldPlayerData {
				playerName = "", -- The nickname of the player.
				id = 0, -- The temporary id of the player during the section.
				isShaman = false, -- Whether the player is shaman or not.
				isDead = false, -- Whether the player is dead or not.
				score = 0, -- The current player score.
				hasCheese = false, -- Whether the player has cheese or not.
				title = 0, -- The id of the current title of the player.
				titleStars = 0, -- The quantity of starts that the current title of the player has.
				gender = 0, -- The gender of the player. Enum in enum.gender.
				look = "", -- The current outfit string code of the player.
				mouseColor = 0, -- The color of the player. It is set to -1 if it's the default color.
				shamanColor = 0, -- The color of the player as shaman.
				nameColor = 0, -- The color of the nickname of the player.
				isSouris = false, -- Whether the player is souris or not.
				isVampire = false, -- Whether the player is vampire or not.
				hasWon = false, -- Whether the player has joined the hole in the round or not.
				winPosition = 0, -- The position where the player joined the hole. It is set to -1 if it has not won yet.
				winTimeElapsed = 0, -- The time elapsed when the player joined the hole. It is set to -1 if it has not won yet.
				isFacingRight = false, -- Whether the player is facing right or not.
				movingRight = false, -- Whether the player is moving right or not.
				movingLeft = false, -- Whether the player is moving left or not.
				isBlueShaman = false, -- Whether the player is the blue shamamn or not.
				isPinkShaman = false, -- Whether the player is the pink shamamn or not.
				x = 0, -- The coordinate X of the player in the map.
				y =  0, -- The coordinate Y of the player in the map.
				vx = 0, -- The X speed of the player in the map.
				vy =  0, -- The Y speed of the player in the map.
				isDucking = false, -- Whether the player is ducking or not.
				isJumping = false, -- Whether the player is jumping or not.
				_pos = 0 -- The position of the player in the array list. This value should never be changed manually.
			}
		]]
		self.event:emit((eventName or "updatePlayer"), self.playerList[playerId], (oldPlayerData or (sendValue and fieldValue)))
	end
end

--[[@
	@desc Initializes the API connection with the authentication keys. It must be the first method of the API to be called.
	@desc This function can be called only once.
	@param tfmId<string,int> The Transformice ID of your account. If you don't know how to obtain it, go to the room **#bolodefchoco0id** and check your chat.
	@param token<string> The API Endpoint token to get access to the authentication keys.
]]
client.start = coroutine.wrap(function(self, tfmId, token)
	getKeys(self, tfmId, token)
	getKeys = nil -- Saves memory

	self.main:connect(enum.setting.mainIp)

	self.main.event:once("_socketConnection", function()
		local packet = byteArray:new():write16(self._gameVersion):writeUTF(self._gameConnectionKey)
		packet:writeUTF("Desktop"):writeUTF('-'):write32(8125):writeUTF('')
		packet:writeUTF("86bd7a7ce36bec7aad43d51cb47e30594716d972320ef4322b7d88a85904f0ed")
		packet:writeUTF("A=t&SA=t&SV=t&EV=t&MP3=t&AE=t&VE=t&ACC=t&PR=t&SP=f&SB=f&DEB=f&V=LNX 29,0,0,140&M=Adobe Linux&R=1920x1080&COL=color&AR=1.0&OS=Linux&ARCH=x86&L=en&IME=t&PR32=t&PR64=t&LS=en-US&PT=Desktop&AVD=f&LFD=f&WD=f&TLS=t&ML=5.1&DP=72")
		packet:write32(0):write32(25175):writeUTF('')

		self.main:send(enum.identifier.initialize, packet)

		receive(self, "main")
		receive(self, "bulle")
		local loop
		loop = timer.setInterval(10, function(self, loop)
			if not self.main.open then
				timer.clearInterval(self._hbTimer)
				timer.clearInterval(loop)
				closeAll(self)
			end
		end, self, loop)
	end)

	self.main.event:on("_receive", function(connection, packet)
		local identifiers = { packet:read8(), packet:read8() }

		if connection.name == "main" then
			if enum.identifier.correctVersion[1] == identifiers[1] and enum.identifier.correctVersion[2] == identifiers[2] then
				return timer.setTimeout(5000, function(self)
					--[[@
						@desc Triggered when the connection is live.
					]]
					self.event:emit("ready")
				end, self)
			elseif enum.identifier.bulleConnection[1] == identifiers[1] and enum.identifier.bulleConnection[2] == identifiers[2] then
				self._connectionTime = os.time()
				return timer.setTimeout(5000, function(self)
					--[[@
						@desc Triggered when the player is logged and ready to perform actions.
					]]
					self.event:emit("connection")
				end, self)
			end
		end
		--[[@
			@desc Triggered when the client receives packets from the server.
			@param connection<connection> The connection object that received the packets.
			@param identifiers<table> The C, CC identifiers that were received.
			@param packet<byteArray> The Byte Array object that was received.
		]]
		self.event:emit("receive", connection, identifiers, packet)
	end)
end)
--[[@
	@desc Sets an event emitter that is triggered everytime the specific behavior happens.
	@desc See the available events in @see Events.
	@param eventName<string> The name of the event.
	@param callback<function> The function that must be called when the event is triggered.
]]
client.on = function(self, eventName, callback)
	return self.event:on(eventName, coroutine.makef(callback))
end
--[[@
	@desc Sets an event emitter that is triggered only once when a specific behavior happens.
	@desc See the available events in @see Events.
	@param eventName<string> The name of the event.
	@param callback<function> The function that must be called only once when the event is triggered.
]]
client.once = function(self, eventName, callback)
	return self.event:once(eventName, coroutine.makef(callback))
end
--[[@
	@desc Emits an event.
	@desc See the available events in @see Events. You can also create your own events / emitters.
	@param eventName<string> The name of the event.
	@param ...?<*> The parameters to be passed during the emitter call.
]]
client.emit = function(self, eventName, ...)
	return self.event:emit(eventName, ...)
end
--[[@
	@desc Gets the total time of the connection.
	@returns int The total time since the connection.
]]
client.connectionTime = function(self)
	return os.time() - self._connectionTime
end
--[[@
	@desc Forces the private function @see closeAll to be called.
	@returns boolean Whether the Connection objects can be destroyed or not.
]]
client.closeAll = function(self)
	if self.main then
		self.main.open = false
		return true
	end
	return false
end

-- Methods
-- Initialization
--[[@
	@desc Sets the community where the bot will be connected to.
	@desc /!\ This method must be called before the @see start.
	@param community?<enum.community> An enum from @see community. (index or value) @default EN
]]
client.setCommunity = function(self, community)
	community = enum._validate(enum.community, enum.community.en, community, string.format(enum.error.invalidEnum, "setCommunity", "community", "community"))
	if not community then return end

	self.community = community
end
--[[@
	@desc Connects to an account in-game.
	@desc It will try to connect using all the available ports before throwing a timing out error.
	@param userName<string> The name of the account. It must contain the discriminator tag (#).
	@param userPassword<string> The password of the account.
	@param startRoom?<string> The name of the initial room. @default "*#bolodefchoco"
]]
client.connect = function(self, userName, userPassword, startRoom, timeout)
	userName = string.toNickname(userName, true)

	local packet = byteArray:new():writeUTF(userName):writeUTF(encode.getPasswordHash(userPassword))
	packet:writeUTF("app:/TransformiceAIR.swf/[[DYNAMIC]]/2/[[DYNAMIC]]/4"):writeUTF((startRoom and tostring(startRoom)) or "*#bolodefchoco")
	packet:write32(bit.bxor(self._receivedAuthkey, self._gameAuthkey))

	self.playerName = userName
	self.main:send(enum.identifier.login, encode.btea(packet):write8(0))

	timer.setTimeout((timeout or (20 * 1000)), function(self)
		if not self._isConnected then
			return error("↑error↓[LOGIN]↑ Impossible to log in. Try again later.", enum.errorLevel.low)
		end
	end, self)
end
-- Room
--[[@
	@desc Enters in a room.
	@param roomName<string> The name of the room.
	@param isSalonAuto?<boolean> Whether the change room must be /salonauto or not. @default false
]]
client.enterRoom = function(self, roomName, isSalonAuto)
	self.main:send(enum.identifier.room, byteArray:new():write8(self.community):writeUTF(roomName):writeBool(isSalonAuto))
end
--[[@
	@desc Sends a message in the room chat.
	@desc /!\ Note that the limit of characters for the message is 255, but if the account is new the limit is set to 80. You must limit it yourself or the bot may get disconnected.
	@param message<string> The message.
]]
client.sendRoomMessage = function(self, message)
	self.bulle:send(enum.identifier.roomMessage, encode.xorCipher(byteArray:new():writeUTF(message), self.bulle.packetID))
end
-- Whisper
--[[@
	@desc Sends a whisper to an user.
	@desc /!\ Note that the limit of characters for the message is 255, but if the account is new the limit is set to 80. You must limit it yourself or the bot may get disconnected.
	@param message<string> The message.
	@param targetUser<string> The user to receive the whisper.
]]
client.sendWhisper = function(self, targetUser, message)
	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(52):write32(3):writeUTF(targetUser):writeUTF(message), self.main.packetID))
end
--[[@
	@desc Sets the account's whisper state.
	@param message?<string> The /silence message. @default ''
	@param state?<enum.whisperState> An enum from @see whisperState. (index or value) @default enabled
]]
client.changeWhisperState = function(self, message, state)
	state = enum._validate(enum.whisperState, enum.whisperState.enabled, state, string.format(enum.error.invalidEnum, "changeWhisperState", "state", "whisperState"))
	if not state then return end

	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(60):write32(1):write8(state):writeUTF(message or ''), self.main.packetID))
end
-- Chat
--[[@
	@desc Joins a #chat.
	@param chatName<string> The name of the chat.
]]
client.joinChat = function(self, chatName)
	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(54):write32(1):writeUTF(chatName):write8(1), self.main.packetID))
end
--[[@
	@desc Sends a message to a #chat.
	@desc /!\ Note that the limit of characters for the message is 255, but if the account is new the limit is set to 80. You must limit it yourself or the bot may get disconnected.
	@param chatName<string> The name of the chat.
	@param message<string> The message.
]]
client.sendChatMessage = function(self, chatName, message)
	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(48):write32(1):writeUTF(chatName):writeUTF(message), self.main.packetID))
end
--[[@
	@desc Leaves a #chat.
	@param chatName<string> The name of the chat.
]]
client.closeChat = function(self, chatName)
	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(56):write32(1):writeUTF(chatName), self.main.packetID))
end
--[[@
	@desc Gets who is in a specific chat. (/who)
	@param chatName<string> The name of the chat.
]]
client.chatWho = function(self, chatName)
	self._who_fingerprint = (self._who_fingerprint + 1) % 500
	self._who_list[self._who_fingerprint] = chatName

	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(58):write32(self._who_fingerprint):writeUTF(chatName), self.main.packetID))
end
-- Tribe
--[[@
	@desc Joins the tribe house, if the account is in a tribe.
]]
client.joinTribeHouse = function(self)
	self.main:send(enum.identifier.joinTribeHouse, byteArray:new())
end
--[[@
	@desc Sends a message to the tribe chat.
	@desc /!\ Note that the limit of characters for the message is 255, but if the account is new the limit is set to 80. You must limit it yourself or the bot may get disconnected.
	@param message<string> The message.
]]
client.sendTribeMessage = function(self, message)
    self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(50):write32(3):writeUTF(message), self.main.packetID))
end
--[[@
	@desc Sends a recruitment invite to the player.
	@desc /!\ Note that this method will not cover errors if the account is not in a tribe or do not have permissions.
	@param playerName<string> The name of player to be recruited.
]]
client.recruitPlayer = function(self, playerName)
	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(78):write32(1):writeUTF(playerName), self.main.packetID))
end
--[[@
	@desc Kicks a member of the tribe.
	@desc /!\ Note that this method will not cover errors if the account is not in a tribe or do not have permissions.
	@param memberName<string> The name of the member to be kicked.
]]
client.kickTribeMember = function(self, memberName)
	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(104):write32(1):writeUTF(memberName), self.main.packetID))
end
--[[@
	@desc Sets the role of a member in the tribe.
	@desc /!\ Note that this method will not cover errors if the account is not in a tribe or do not have permissions.
	@param memberName<string> The name of the member to get the role.
	@param roleId<int> The role id. (starts in 0, for the initial role. Increases until the Chief role)
]]
client.setTribeMemberRole = function(self, memberName, roleId)
	self.main:send(enum.identifier.bulle, encode.xorCipher(byteArray:new():write16(112):write32(1):writeUTF(memberName):write8(roleId), self.main.packetID))
end
--[[@
	@desc Loads a lua script in the room.
	@param script<string> The lua script.
]]
client.loadLua = function(self, script)
	self.bulle:send(enum.identifier.loadLua, byteArray:new():writeBigUTF(script))
end
-- Café
--[[@
	@desc Reloads the Café data.
]]
client.reloadCafe = function(self)
	self.main:send(enum.identifier.cafeData, byteArray:new())
end
--[[@
	@desc Toggles the current Café state (open / closed).
	@desc It will send @see client.reloadCafe automatically if close is false.
	@param close?<boolean> If the Café must be closed. @default false
]]
client.openCafe = function(self, close)
	close = not close
	self.main:send(enum.identifier.cafeState, byteArray:new():writeBool(close))
	if close then -- open = reload
		client:reloadCafe()
	end
end
--[[@
	@desc Creates a Café topic.
	@desc /!\ The method does not handle the Café's cooldown system.
	@param title<string> The title of the topic.
	@param message<string> The content of the topic.
]]
client.createCafeTopic = function(self, title, message)
	message = string.gsub(message, "\r\n", "\r")
	self.main:send(enum.identifier.cafeNewTopic, byteArray:new():writeUTF(title):writeUTF(message))
end
--[[@
	@desc Opens a Café topic.
	@desc You may use this method to reload the topic (refresh).
	@param topicId<int> The id of the topic to be opened.
]]
client.openCafeTopic = function(self, topicId)
	self.main:send(enum.identifier.cafeLoadData, byteArray:new():write32(topicId))
end
--[[@
	@desc Sends a message in a Café topic.
	@desc /!\ The method does not handle the Café's cooldown system: 300 seconds if the last post is from the same account, otherwise 10 seconds.
	@param topicId<int> The id of the topic where the message will be posted.
	@param message<string> The message to be posted.
]]
client.sendCafeMessage = function(self, topicId, message)
	message = string.gsub(message, "\r\n", "\r")
	self.main:send(enum.identifier.cafeSendMessage, byteArray:new():write32(topicId):writeUTF(message))
end
--[[@
	@desc Likes/Dislikes a message in a Café topic.
	@desc /!\ The method does not handle the Café's cooldown system: 300 seconds to react in a message.
	@param topicId<int> The id of the topic where the message is located.
	@param messageId<int> The id of the message that will receive the reaction.
	@param dislike?<boolean> Whether the reaction must be a dislike or not. @default false
]]
client.likeCafeMessage = function(self, topicId, messageId, dislike)
	self.main:send(enum.identifier.cafeLike, byteArray:new():write32(topicId):write32(messageId):writeBool(not dislike))
end

-- Miscellaneous
--[[@
	@desc Sends a command (/).
	@desc /!\ Note that some unlisted commands cannot be triggered by this function.
	@param command<string> The command. (without /)
]]
client.sendCommand = function(self, command, crypted)
	self.main:send(enum.identifier.command, encode.xorCipher(byteArray:new():writeUTF(command), self.main.packetID))
end
--[[@
	@desc Plays an emote.
	@param emote?<enum.emote> An enum from @see emote. (index or value) @default dance
	@param flag?<string> The country code of the flag when @emote is flag.
]]
client.playEmote = function(self, emote, flag)
	emote = enum._validate(enum.emote, enum.emote.dance, emote, string.format(enum.error.invalidEnum, "playEmote", "emote", "emote"))
	if not emote then return end


	local packet = byteArray:new():write8(emote):write32(0)
	if emote == enum.emote.flag then
		packet = packet:writeUTF(flag)
	end

	self.bulle:send(enum.identifier.emote, packet)
end
--[[@
	@desc Plays an emoticon.
	@param emoticon?<enum.emoticon> An enum from @see emoticon. (index or value) @default smiley
]]
client.playEmoticon = function(self, emoticon)
	emoticon = enum._validate(enum.emoticon, enum.emoticon.smiley, emoticon, string.format(enum.error.invalidEnum, "playEmoticon", "emoticon", "emoticon"))
	if not emoticon then return end

	self.bulle:send(enum.identifier.emoticon, byteArray:new():write8(emoticon):write32(0))
end
--[[@
	@desc Requests the data of a room mode list.
	@param roomMode?<enum.roomMode> An enum from @see roomMode. (index or value) @default normal
]]
client.requestRoomList = function(self, roomMode)
	roomMode = enum._validate(enum.roomMode, enum.roomMode.normal, roomMode, string.format(enum.error.invalidEnum, "requestRoomList", "roomMode", "roomMode"))
	if not roomMode then return end

	self.main:send(enum.identifier.roomList, byteArray:new():write8(roomMode))
end

return client