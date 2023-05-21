  --[[lit-meta
    name = "lil-evil/ansi"
    version = "1.0.0"
    dependencies = { }
    description = "ansi code library for terminal"
    tags = { "ansi", "terminal" }
    license = "MIT"
    author = { name = "lilevil" }
    homepage = "https://github.com/lil-evil/lua-ansi"
  ]]
  
---@diagnostic disable: undefined-doc-param
---@module ansi
local Ansi = {
  package = {version="1.0.0"},
  escape = "\x1b",
  pattern = "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]",
}

local unpack = (unpack or table.unpack)

-- ####################### GRAPHICS #######################
Ansi.format = {
  reset = 0,
  -- styles
  style_invert = 20,   -- disable/invert style
  bold = 1,            -- invert mode is 22 not 21
  dim = 2,
  italic = 3,
  underline = 4,
  blinking = 5,
  inverse = 7,
  hidden = 8,
  strikethrough = 9,
  -- colors
  color_bg = 10,      -- to set to a bg color
  color_bright = 60,  -- to set to a bright color
  black = 30,
  red = 31,
  green = 32,
  yellow = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37,
  default = 39,
}

function Ansi.format.construct(...)
  local arg = arg or {...}
  local an = Ansi.escape .. "["
  for i, v in ipairs(arg) do
    an = an .. v .. (i < #arg and ";" or "")
  end
  return an .. "m"
end

function Ansi.format.rgb(r,g,b, bg)
  return Ansi.format.construct(38 + (bg and Ansi.format.color_bg or 0), 2, r, g, b)
end
function Ansi.format.color_id(id, bg)
  return Ansi.format.construct(38 + (bg and Ansi.format.color_bg or 0), 5, id)
end
local t = {}
function t.__call(self, ...)
  local arg = arg or {...}
  local results = {}

  for i, v in ipairs(arg) do
    if type(v) ~= "string" then 
      error("Cannot parse a " .. type(v) .. ".")
    end

    -- %{<color> bg_<color> bright_<color> <style> #<style>}
    local res = v:gsub("%%{([^}]+)}", function(str)
      local values = {}
      local rgb = nil
      
      str:gsub("([^,^%s]+)", function(key)
        
        local invert = false
        if key:match("^#") then -- disable style
            invert = true
            key = key:gsub("^#", "")
        end
        local meta, color = key:match("^([^_]+)_([^_]+)$")
        if not meta then -- no meta to apply (bg, bright)
          color = key 
        end

        if color:match("^%d+$") then -- color index
          rgb = Ansi.format.color_id(tonumber(color), meta == "bg")
          return
        end

        if color:match("^%d+-%d+-%d+$") then -- color rgb
        local r, g, b = color:match("^(%d+)-(%d+)-(%d+)$")
          rgb = Ansi.format.rgb(r, g, b, meta == "bg")
          return
        end

        local value = Ansi.format[color]
        if type(value) ~= "number" or (value == Ansi.format.color_bg) or (value == Ansi.format.color_bright) then return end

        if value == 0 then  -- reset
          table.insert(values, value) 
          return 
        end
        if value < 10 then --style
          if invert then 
            if value == Ansi.format.bold then -- bold invert = 22 not 21
              value = value+1 
            end
            
            value = value + Ansi.format.style_invert
          end

          table.insert(values, value)
          return
        end

        -- color
        if meta == "bright" then
          value = value + Ansi.format.color_bright
        end
        if meta == "bg" then
          value = value + Ansi.format.color_bg
        end

        table.insert(values, value)
        return
      end) -- params parser
      return Ansi.format.construct(unpack(values)) .. (rgb and rgb or "")
    end)

    res = res .. Ansi.format.construct(Ansi.format.reset)
    table.insert(results, res)
    
  end

  return unpack(results)
end
Ansi.format = setmetatable(Ansi.format, t)
-- ####################### CURSOR #######################
Ansi.cursor = {

}

-- ####################### KEYBOARD #######################
Ansi.keyboard = {
  
}

-- ####################### MOUSE #######################
Ansi.mouse = {
  
}

-- ####################### SCREEN #######################
Ansi.screen = {
  
}

return Ansi
