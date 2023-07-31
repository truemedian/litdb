local handlePlayers = require("api/Client/utils/_internal/handlePlayers")

local updateFlag = require("api/enum").updatePlayer.score

local onScore = function(self, packet, connection, identifiers)
	if not handlePlayers(self) then return end

	local player = self.playerList[packet:read32()]
	if not player then return end

	local oldPlayerData = player:copy()
	player.score = packet:read16()

	self.event:emit("updatePlayer", player, oldPlayerData, updateFlag)
end

return { onScore, 8, 7 }