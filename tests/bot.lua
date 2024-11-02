local discordia = require('../init')
local client = discordia.Client({
	gatewayIntents = 53608447
})

local musicalControls = discordia.Components {
  {
    id = "skip_backwards",
    type = "button",
    label = "Previous Song",
    emoji = "⏪",
  },
  {
    id = "resume",
    type = "button",
    label = "Resume Song",
    emoji = "▶️",
  },
  {
    id = "pause",
    type = "button",
    label = "Pause Song",
    emoji = "⏸️",
  },
  {
    id = "skip_forward",
    type = "button",
    label = "Next Song",
    style = "secondary",
    emoji = "⏩",
  },
  {
    id = "abort",
    type = "button",
    label = "Abort Song",
    style = "danger",
    actionRow = 2,
  },
}

client:on('ready', function()
	print('Logged in as '.. client.user.username)
end)

client:on("interactionCreate", function(interaction)
  interaction:reply("Hello world")
end)

client:on('messageCreate', function(message)
	if message.content == "!hello" then
		message:replyComponents("Here your music controls!", musicalControls)
	end
end)

client:run('OTc3MTQ4MzIxNjgyNTc1NDEw.G7EX97.GuZKU7YNEusRL_JnUeALRS9NldHh_mOzf1hJDw')