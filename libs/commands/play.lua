local wrap = corotuine.wrap

return setmetatable({ 'play', alias = 'p' }, {
	__call = function(self, data)
		local vc = data.message.member.voiceChannel
		if not vc then
			return data.message:reply'Make sure you\'re joinned a voice channel.'
		elseif bot.connections[data.message.guild.id] then
			return
		end

		local split = data.split
		local core = self._parent()._parent()._core

		local url = core.parse(split[1] or '')

		local function play(this)
			core.videoInfoCard(this, function(response)
				local connection = bot.connections[data.message.guild.id] or vc:join()
				if connection then
					bot.connections[data.message.guild.id] = connection

					wrap(function()
						connection:playFFmpeg(response.url)
					end)()

					data.message:reply({
						embed = {
							title = string.format('Playing %s', response.title),
							description = string.format('Duration: %s', response.duration),
							image = { url = response.thumbnail }
						}
					})
				end
			end)
		end

		local content = data.message.content
		if not url.protocol and split[1] then
			data.message:reply'I am currently decoding your search, please wait.'
			local _, _end = content:find(data.command)
			local search = content:sub(_end + 1)

			play(search)
		elseif split[1] then
			play(split[1])
		else
			return data.message:reply'Please give a url/search.'
		end
	end
})