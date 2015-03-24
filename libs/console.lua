--[[

The MIT License (MIT)

Copyright (c) 2015 gsick

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]

local Object = require("core").Object
local String = require("string")
local Print  = require("pretty-print")

local Levels = require("./utils").Levels
local Utils  = require("./utils")

local _ConsoleLogger = Object:extend()

function _ConsoleLogger:initialize(options)

  self.type = options.type

  self.level = nil
  if type(options.level) == "string" and Levels[String.lower(options.level)] then
    self.level = Levels[String.lower(options.level)]
  end

  self.dateformat = nil
  if options.dateformat and type(options.dateformat) == "string" then
    self.dateformat = options.dateformat
  end

  self.color = options.color or false

end

function _ConsoleLogger:log(parent_level, level, s, ...)

  local final_level = self.level or parent_level

  if level.value > final_level.value then
    return
  end

  local final_string = Utils.finalString(self.dateformat, level, s, ...)
  if self.color then
    if level.value == Levels["error"].value then
      print(Print.colorize("red", final_string))
    elseif level.value == Levels["warn"].value then
      print(Print.colorize("yellow", final_string))
    elseif level.value == Levels["info"].value then
      print(final_string)
    elseif level.value == Levels["debug"].value then
      print(Print.colorize("green", final_string))
    elseif level.value == Levels["trace"].value then
      print(Print.colorize("cyan", final_string))
    end
  else
    print(final_string)
  end
end

function _ConsoleLogger:close()

end

return _ConsoleLogger
