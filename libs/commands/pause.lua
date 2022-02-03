return setmetatable( { 'pause' }, {
	__call = function(self, data)
		local connection = bot.connections[data.message.guild.id]
		if not connection then
			return nil
		end

		coroutine.wrap(function()
			connection:pauseStream()
		end)()
	end
} )