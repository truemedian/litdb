local discordia = require 'discordia'

local toast = require 'SuperToast'

local stringx = toast.stringx

local Color = discordia.Color
local f = string.format

local function smudgeColor(colorA, colorB, percent)
   return {
      r = colorA.r - (colorA.r - colorB.r) * percent,
      g = colorA.g - (colorA.g - colorB.g) * percent,
      b = colorA.b - (colorA.b - colorB.b) * percent
   }
end

local function splitCol(str)
   local tbl = {}

   local pos = 1
   for _, char in pairs(stringx.split(str)) do
      if not tbl[pos] then
         tbl[pos] = ''
      end

      if char == '\n' then
         pos = 1
         goto continue
      end

      tbl[pos] = tbl[pos] .. char

      pos = pos + 1

      ::continue::
   end

   return tbl
end

--- Blend 2 colors together within text
---@param str string The text to colorize
---@param start number The starting color value
---@param stop number The ending color value
---@return string colorized The colorized string
local function blend(str, start, stop)
   local cols = splitCol(str)

   local colors = {}

   local startRgb = Color(start)
   local stopRgb = Color(stop)

   local maxColorLen = #cols

   for i = 1, maxColorLen do
      table.insert(colors, smudgeColor(startRgb, stopRgb, i / maxColorLen))
   end

   local rows = {}

   for i, col in pairs(cols) do
      local color = colors[i]

      local pos = 1

      for _, char in pairs(stringx.split(col)) do
         local colorized = f("\27[38;2;%i;%i;%im", math.floor(color.r), math.floor(color.g), math.floor(color.b)) .. char .. '\27[0m'

         if not rows[pos] then
            rows[pos] = ''
         end

         rows[pos] = rows[pos] .. colorized

         pos = pos + 1
      end
   end

   return table.concat(rows, '\n')
end

return blend