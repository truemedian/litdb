local Client = require("api/Client/init")

local ByteArray = require("classes/ByteArray")

local identifier = require("api/enum").identifier.acceptTribeHouseInvite

--[[@
	@name acceptTribeHouseInvitation
	@desc Accepts a tribe house invitation and joins the tribe's tribehouse.
	@desc /!\ Note that this method will not cover errors if the account is not in a tribe or does not have permissions.
	@param inviterName<string> The name of who has invited the bot.
]]
Client.acceptTribeHouseInvitation = function(self, inviterName)
	self.mainConnection:send(identifier, ByteArray:new():writeUTF(inviterName))
end