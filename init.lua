-- MIT License
--
-- Copyright (c) 2020 Martín Aguilar
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local h = {
  _VERSION = '0.1.0'
}

-- Append a value at the end of a table
local function append(t, v)
  t[#t + 1] = v
end

-- Escape HTML from a string
local function escape_html(s)
  return (string.gsub(s, "[}{\">/<'&]", {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
    ["/"] = "&#47;"
  }))
end

function h.h(tag, opts, content)
  local options = {}

  if type(opts) == 'table' then
    for k, v in pairs(opts) do
      if type(v) == 'boolean' then
        append(options, k)
      else
        append(options, k .. '="' .. v .. '"')
      end
    end
  elseif type(opts) == 'string' then
    content = opts
  elseif tag and not opts then
    content = nil
  else
    return
  end

  if type(content) == 'string' then
    return '<' .. tag .. (#options >= 1 and ' ' or '') ..
      table.concat(options, ' ') .. '>'
      .. escape_html(content) .. '</' .. tag .. '>'
  elseif type(content) == 'table' then
    return '<' .. tag .. (#options >= 1 and ' ' or '') ..
      table.concat(options, ' ') .. '>'
      .. table.concat(content, '') .. '</' .. tag .. '>'
  elseif not content then
    -- Handle open tags
    return '<' .. tag .. (#options >= 1 and ' ' or '') ..
      table.concat(options, ' ') .. '/>'
  end
end

setmetatable(h, {
  _call = function(_, ...)
    return h.h(...)
  end
})

return h
