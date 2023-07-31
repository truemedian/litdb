local tribulleListener = require("api/Client/Listener/Tribulle/init")

local onTribullePacket = function(self, packet, connection, identifiers)
	local tribulleId = packet:read16()
	if tribulleListener[tribulleId] then
		return tribulleListener[tribulleId](self, packet, connection, tribulleId)
	end

	--[[@
		@name missedTribulle
		@desc Triggered when a tribulle packet is not handled by the tribulle packet parser.
		@param tribulleId<int> The tribulle id.
		@param packet<byteArray> The Byte Array object with the packet that was not handled.
		@param connection<connection> The connection object.
	]]
	self.event:emit("unhandledTribullePacket", tribulleId, packet, connection)
end

return { onTribullePacket, 60, 3 }