local data = require('internal/data')

return function(reaction, userId)
	if data.confirmation[reaction.message.id] and userId ~= reaction.client.user.id then

		local confirmation = data.confirmation[reaction.message.id]

		if reaction.emojiName == "✅" then
			confirmation.handler(confirmation.original, confirmation.response, true)
		elseif reaction.emojiName == "❌" then
			confirmation.handler(confirmation.original, confirmation.response, false)
		else
			return false
		end

	   data.confirmation[reaction.message.id] = nil
	else
		return false
	end
end