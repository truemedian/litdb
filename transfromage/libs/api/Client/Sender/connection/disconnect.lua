local Client = require("api/Client/init")

--[[@
	@name disconnect
	@desc Forces the private function @see closeAll to be called. (Ends the connections)
	@returns boolean Whether the Connection objects can be destroyed or not.
]]
Client.disconnect = function(self)
	if self.mainConnection then
		self.mainConnection.isOpen = false
		return true
	end

	return false
end