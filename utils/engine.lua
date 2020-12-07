---@type discordia
local discordia = require 'discordia'
---@type SuperToast
local toast = require 'SuperToast'

local stringx = toast.stringx
local mathx = discordia.extensions

--- Configuration for the rendering engine
---@class Engine.config
---@field public draw fun(engine: Engine, text: string)

---@alias Engine.direction string | "'up'" | "'down'"

--- A text rendering engine specialized for Discord
---@class Engine
local Engine = discordia.class('Rendering Engine')

---@type Engine | fun(text: string, conf: Engine.config): Engine
Engine = Engine


--- Create a new engine
---@param text string The starting text of the engine
---@param conf Engine.config The configuration to use
---@return Engine
function Engine:__init(text, conf)
   self.lines = stringx.split(text, '\n')
   self.config = conf

   self.pos = 1
   self.text = "" -- Text is filled in
end

--- Render the text and pass it onto the drawer
function Engine:render()
   self.text = stringx.trim(table.concat(self.lines, '\n'))

   return self.config.draw(self, self.text)
end

--- Move the cursor up or down
---@param direction Engine.direction The direction to move the cursor
---@param amount number The amount to move the cursor by
---@param refresh boolean To re-render the display
---@return string | nil
---@overload fun(direction: Engine.direction)
---@overload fun(direction: Engine.direction, amount: number)
function Engine:move(direction, amount, refresh)
   local count = amount and direction == 'up' and -amount or
      amount and direction == 'down' and amount or
      direction == 'up' and -1 or
      direction == 'down' and 1
end