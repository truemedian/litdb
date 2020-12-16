---@type discordia
local discordia = require('discordia')

local enums = discordia.enums

--- A list of enums for slash commands
---@class SlashCommands.enums
---@field public argumentType enums.argumentType
---@field public responseType enums.responseType

--- argumentType enum
---@class enums.argumentType
---@field public subcommand number | "1"
---@field public subcommand_group number | "2"
---@field public string number | "3"
---@field public integer number | "4"
---@field public boolean number | "5"
---@field public user number | "6"
---@field public channel number | "7"
---@field public role number | "8"
local argumentType = enums.enum {
   subcommand = 1,
   subcommand_group = 2,
   string = 3,
   integer = 4,
   boolean = 5,
   user = 6,
   channel = 7,
   role = 8
}

--- responseType enum
---@class enums.responseType
---@field public Pong number | "1" ACK a `Ping`
---@field public Acknowledge number | "2" ACK a command without sending a message, eating the user's input
---@field public ChannelMessage number | "3" respond with a message, eating the user's input
---@field public ChannelMessageWithSource number | "4" respond with a message, showing the user's input
---@field public ACKWithSource number | "5" ACK a command without sending a message, showing the user's input
local responseType = enums.enum {
   Pong = 1,
   Acknowledge = 2,
   ChannelMessage = 3,
   ChannelMessageWithSource = 4,
   ACKWithSource = 5
}

return {
   argumentType = argumentType,
   responseType = responseType
}