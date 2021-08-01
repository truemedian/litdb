local DuaHook = require("DuaHook") -- Requires the module

local Hook = DuaHook.Webhook("(WEBHOOK LINK HERE)") -- You can call the Webhook table cause it has an __call metatable

local Embed = DuaHook.Embed() -- Constructs a embed
    :SetTitle("Hello!") -- Sets embed title
    :SetColor(DuaHook.Color(255, 0, 0)) -- DuaHook.Color is based on RGB.
-- ^^^ You can do this cause all methods return the embed object.

local Message = DuaHook.Message() -- Constructs a message
    :SetContent("From DuaHook: ") -- Sets message content
    :AddEmbed(Embed) -- Adds the embed

Hook:Send(Message) -- Sends message