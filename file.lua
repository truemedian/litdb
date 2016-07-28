--[[lit-meta
  name = "SoniEx2/mdxml"
  version = "0.0.1"
  description = "Markdown Extensible Markup Language and Markdown-serialized XML (MDXML) Parser, LPeg-based"
  tags = { "mdxml", "lpeg" }
  license = "BSL-1.0"
  author = { name = "Soni L." }
  homepage = "https://bitbucket.org/SoniEx2/mdxml"
  dependencies = {}
]]

local lpeg = require 'lpeg'
local type = type
local error = error

local mdxml = {}

local eof = lpeg.P(-1)
local nl = (lpeg.P "\r")^-1 * lpeg.P "\n" + lpeg.P "\\n" + eof -- \r for winblows compat
local nlnoeof = (lpeg.P "\r")^-1 * lpeg.P "\n" + lpeg.P "\\n"
local ws = lpeg.S(" \t") + nlnoeof - nl * nl 
local inlineComment = lpeg.P("`") * (1 - (lpeg.S("`") + nl * nl)) ^ 0 * lpeg.P("`")
local wsc = ws + inlineComment -- comments count as whitespace
local backslashEscaped
= lpeg.P("\\ ") / " " -- escaped spaces
+ lpeg.P("\\\\") / "\\" -- escaped escape character
+ lpeg.P("\\#") / "#"
+ lpeg.P("\\>") / ">"
+ lpeg.P("\\`") / "`"
+ lpeg.P("\\n") -- \\n newlines count as backslash escaped
+ lpeg.P("\\") * lpeg.P(function(_, i)
    error("Unknown backslash escape at position " .. i)
  end)
local Line = lpeg.Cs((wsc / " " + (backslashEscaped + 1 - nl))^0) * nl * lpeg.Cp()
local Data = lpeg.S(" \t")^0 * lpeg.Cs((wsc / " " + (backslashEscaped + 1 - (lpeg.S(" \t")^0 * nl)))^0) * lpeg.S(" \t")^0 * nl
local LineIgnored = (wsc + (1 - nl))^0 * nl * lpeg.Cp()
local Empty = (lpeg.P(">") * lpeg.S(" ")^-1)^0 * nl
local Depth = (lpeg.P(">") * lpeg.S(" ")^-1)^0 / function(x)
  local _, subcount = x:gsub(">", "")
  return subcount
end * lpeg.Cp()

function mdxml.parse(s)
  local _ -- ignored
  local pos = 1
  local len = #s
  local doc = {}
  local lastattr = {}
  local depth = 0
  while pos < len do
    local line, newpos = Line:match(s, pos)
    local oldpos = pos
    pos = newpos
    if Empty:match(line) then
      depth = 0
    else
      local linedepth, x = Depth:match(line)
      if depth < linedepth then
        depth = linedepth
      end
      local t = doc
      for i=1,depth do
        t = t[#t]
      end
      local contents = line:sub(x)
      if contents:sub(1,1) == "#" then -- tag/attr/etc
        if contents:sub(1,6) == "######" then
          -- TODO create macro system
          error("Invalid ######")
        elseif contents:sub(1,5) == "#####" then -- attrns
          local y = t[#t]
          if type(y) ~= "table" then
            error("Illegal #####")
          end
          local oldattr = lastattr[y]
          if not oldattr then
            error("Illegal #####")
          end
          local oldval = y[oldattr]
          if type(oldval) == "table" then
            error("Duplicate #####")
          end
          y[oldattr] = {attrns=Data:match(contents:sub(6)), value=oldval}
        elseif contents:sub(1,4) == "####" then -- tagns
          local y = t[#t]
          if type(y) ~= "table" then
            error("Illegal ####")
          end
          if type(y[0]) ~= "string" then
            error("Duplicate ####")
          end
          y[0] = {tag=y[0], tagns=Data:match(contents:sub(5))}
        elseif contents:sub(1,3) == "###" then -- val
          local y = t[#t]
          if type(y) ~= "table" then
            error("Illegal ###")
          end
          if not lastattr[y] then
            error("Illegal ###")
          end
          local z = y[lastattr[y]]
          if type(z) == "string" then
            error("Duplicate ###")
          elseif type(z) == "table" then
            if z.value then
              error("Duplicate ###")
            end
            z.value = Data:match(contents:sub(4))
          else
            y[lastattr[y]] = Data:match(contents:sub(4))
          end
        elseif contents:sub(1,2) == "##" then -- attr
          local y = t[#t]
          if type(y) ~= "table" then
            error("Illegal ##")
          end
          local attr = Data:match(contents:sub(3))
          if y[attr] or attr == lastattr[y] then
            error("Duplicate ##")
          end
          lastattr[y] = attr
        elseif contents:sub(1,1) == "#" then -- tag
          t[#t+1] = {[0]=Data:match(contents:sub(2))}
        end
      elseif contents:sub(1,4) == "    " then -- raw block
        t[#t+1] = contents:sub(5)
      elseif contents:sub(1,3) == "```" then -- long comment
        local _pos = pos
        pos = s:match("```()", pos + x)
        if not pos then
          error("Unclosed long comment at position " .. _pos + x)
        end
        _, pos = LineIgnored:match(s, pos) -- align to next newline
      else -- anything else
        t[#t+1] = Data:match(contents)
      end
    end
  end
  return doc
end

return mdxml

