------------------------------------------- Optimization -------------------------------------------
local os_time = os.time
----------------------------------------------------------------------------------------------------

local onLogin = function(self, packet, connection, identifiers)
	self._isConnected = true
	self._loginTime = os_time()

	local playerId = packet:read32()
	self.playerName = packet:readUTF()
	local playedTime = packet:read32()

	--[[@
		@name connection
		@desc Triggered when the player is logged in and ready to perform actions.
		@param playerId<int> The temporary id of the player during the section.
		@param playerName<string> The name of the player that has connected.
		@param playedTime<int> The time played by the player.
	]]
	self.event:emit("mainConnection", playerId, self.playerName, playedTime)
end

return { onLogin, 26, 2 }