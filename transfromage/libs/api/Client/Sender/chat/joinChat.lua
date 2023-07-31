local Client = require("api/Client/init")

local ByteArray = require("classes/ByteArray")

--[[@
	@name joinChat
	@desc Joins a #chat.
	@param chatName<string> The name of the chat.
]]
Client.joinChat = function(self, chatName)
	self.chatList:get(chatName).isOpen = true
	self:sendTribulle(ByteArray:new():write16(54):write32(1):writeUTF(chatName):write8(1))
end