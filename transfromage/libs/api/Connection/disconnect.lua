local Connection = require("./init")

------------------------------------------- Optimization -------------------------------------------
local timer_clearInterval  = require("timer").clearInterval
----------------------------------------------------------------------------------------------------

--[[@
	@name close
	@desc Ends the socket connection.
]]
Connection.close = function(self)
	if not self.socket then return end

	if self._listenLoop then
		timer_clearInterval(self._listenLoop)
	end

	self.isOpen = false
	self.port = 1
	self.socket:destroy()
	self.packetID = 0

	--[[@
		@name disconnection
		@desc Triggered when a connection dies or fails.
		@param connection<connection> The connection object.
	]]
	self._client.event:emit("disconnection", self)
end