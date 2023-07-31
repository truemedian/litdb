local Cafe = require("api/Entities/cafe/Cafe")
local ChatList = require("api/Entities/chat/ChatList")
local Connection = require("api/Connection")
local PlayerList = require("api/Entities/player/PlayerList")
local Shop = require("api/Entities/shop/Shop")

------------------------------------------- Optimization -------------------------------------------
local enum_language = require("api/enum").language
local eventEmitter  = require("core").Emitter
local setmetatable  = setmetatable
----------------------------------------------------------------------------------------------------

local Client = table.setNewClass("Client")

--[[@
	@name new
	@desc Creates a new instance of Client. Alias: `client()`.
	@desc The function @see start is automatically called if you pass its arguments.
	@param tfmId?<string,int> The Transformice ID of your account. If you don't know how to obtain it, go to the room **#bolodefchoco0id** and check your chat.
	@param token?<string> The API Endpoint token to get access to the authentication keys.
	@param hasSpecialRole?<boolean> Whether the bot has the game's special role bot or not.
	@param updateSettings?<boolean> Whether the IP/Port settings should be updated by the endpoint or not when the @hasSpecialRole is true.
	@returns client The new Client object.
	@struct {
		playerName = "", -- The nickname of the account that is attached to this instance, if there's any.
		language = 0, -- The language enum where the object is set to perform the login. Default value is EN.
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
		_whoFingerprint = 0, -- A fingerprint to identify the chat where the command /who was used.
		_whoList = { }, -- A list of chat names associated to their own fingerprints.
		_processXml = false, -- Whether the event "newGame" should decode the XML packet or not. (Set as false to save process)
		_cafeCachedMessages = { }, -- A set of message IDs to cache the read messages at the Café.
		_handlePlayers = false, -- Whether the player-related events should be handled or not. (Set as false to save process)
		_encode = { }, -- The encode object, used to encryption.
		_hasSpecialRole = false, -- Whether the bot has the game's special role bot or not.
		_updateSettings = false -- Whether the IP/Port settings should be updated by the endpoint or not when the @hasSpecialRole is true.
	}
]]
Client.new = function(self)
	local eventEmitter = eventEmitter:new()

	local client = setmetatable({
		playerName = nil,
		language = enum_language.en,
		_isConnected = false,

		tribe = nil,

		mainConnection = nil,
		bulleConnection = nil,
		_heartbeatTimer = nil,

		_loginTime = 0,

		chatList = nil,

		cafe = nil,

		playerList = nil,
		_handlePlayers = false,

		shop = nil,

		room = nil,

		event = eventEmitter,

		_decryptXML = false
	}, self)

	client.mainConnection = Connection:new(client, "main")

	client.chatList = ChatList:new(client)

	client.cafe = Cafe:new(client)

	client.playerList = PlayerList:new(client)

	client.shop = Shop:new(client)

	return client
end

return Client