local wrap = coroutine.wrap

return setmetatable({ 'play', alias = 'p' }, {
	__call = function(self, data)
		local message = data.message

		local vc = message.member.voiceChannel
		if not vc then
			return message:reply '> Please make sure you\'re joinned to a voice channel.\n> ~*These features are currently testing because collecting of intel*.~'
		end

		local split = data.split
		local core = self._parent()._parent()._core

		local url = core.parse(split[1] or '')

		local decodMsg
		local function play(this)
			core.videoInfoCard(this, function(response)
				local connection = bot.connections[message.guild.id] or vc:join()

				if connection then
					local member = connection.channel.guild.me
					member:deafen()
					member:unmute()

					bot.connections[message.guild.id] = connection

					wrap(function()
						connection:playFFmpeg(response.url)
					end)()

					message:reply({
						embed = {
							title = string.format('NOW Playing: %s', response.title),
							description = string.format('\n**Duration: %s**', response.duration),
							image = { url = response.thumbnail },
							footer = {
								text = '→ *Deafened for your comfort*.'
							}
						}
					})

					if decodMsg then
						decodMsg:delete()
					end
				end
			end)
		end

		local content = message.content
		if not url.protocol and split[1] then
			decodMsg = message:reply '> We\'re currently decoding your search (or URL).\n> This won\'t take a lot, please wait.'

			local _, _end = content:find(data.command)
			local search = content:sub(_end + 1)

			play(search)
		elseif split[1] then
			play(split[1])
		else
			return message:reply '> Please give a valid URL, instead; a query.\n> [**TIP**]: At the moment we\'re only supporting "youtube" urls, or query\'s so you can search for a song at a time.'
		end
	end
})