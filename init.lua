return {
    Client = require("./classes/client.lua"),
    Channel = require("./classes/channel.lua"),
    Embed = require("./classes/embed.lua"),
    ActionRow = require("./classes/actionRow.lua"),
    Button = require("./classes/button.lua"),
    Enums = {
        ButtonStyle = {
            PRIMARY = 1,
            SECONDARY = 2,
            SUCCESS = 3,
            DANGER = 4,
            LINK = 5
        },
        InteractionType = {
            PING = 1,
            APPLICATION_COMMAND = 2,
            MESSAGE_COMPONENT = 3,
            APPLICATION_COMMAND_AUTOCOMPLETE = 4,
            MODAL_SUBMIT = 5
        },
        OptionType = {
            SUB_COMMAND = 1,
            SUB_COMMAND_GROUP = 2,
            STRING = 3,
            INTEGER = 4,
            BOOLEAN = 5,
            USER = 6,
            CHANNEL = 7,
            ROLE = 8,
            MENTIONABLE = 9,
            NUMBER = 10,
            ATTACHMENT = 11
        }
    }
}