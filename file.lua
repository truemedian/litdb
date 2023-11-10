--[[lit-meta
    name = "lil-evil/inspect"
    version = "1.0.0"
    dependencies = {
    }
    description = "dump various data to string"
    tags = { "inspect", "dump" }
    license = "MIT"
    author = { name = "lilevil" }
    homepage = "https://github.com/lil-evil/inpect.lua"
  ]]

---@diagnostic disable: undefined-doc-param
---@module inspect

local function esc(code)
  return string.char(27) .. "[" .. code .. "m"
end

local export = {
  default_options = {
    depth = -1,        -- how deep do you need it ?
    table_len = 20,    -- maximum items dumped by tables
    string_len = -1,   -- maximum chars displayed for a string
    colors = false,    -- whether to color the output
    tab_width = 2,     -- with compact=true, how many space to use for tabbing
    item_per_line = 5, -- with compact=true, how many "array" elements can be side by side in a table
    compact = false,   -- on false, output everything in one line, else, output something readable
    escape = true,     -- whether to escape non printable char
    filter = nil,      -- function (key, value) -> boolean to filter parsed data
  },
  default_colors = {
    stop = esc(0),     -- end of the color
    syntax = esc(0),   -- charatacters such as table/string delimitation...
    builtin = esc(31), -- special characters
    ["nil"] = esc(90),
    string = esc(32),
    number = esc(33),
    boolean = esc(36),
    keyword = esc(35),
    class = esc(92),
    metatable = esc(91),
    ["function"] = esc(94),
  }
}

-- http://lua-users.org/wiki/SwitchStatement
local function switch(t)
  t.case = function(self, x)
    local f = self[x] or self.default
    return f
  end
  return t
end

local function table_size(tbl)
  local size = 0
  for k, v in pairs(tbl) do
    size = size + 1
  end
  return size
end
-- https://gist.github.com/tylerneylon/81333721109155b2d244
local function deep_clone(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen and copy recursively.
  local s = seen or {}
  local res = {}
  s[obj] = res
  for k, v in pairs(obj) do res[deep_clone(k, s)] = deep_clone(v, s) end
  return res
end
local dump_function, dump_boolean, dump_nil, dump_string, dump_number, dump_table, dump_thread, dump_userdata, dump_unknown
local dump_custom, dump_metatable

function export.decolorize(str)
  assert(type(str) == "string", "Invalid argument #1. Expected string, got " .. type(str))
  return str:gsub(string.char(27) .. "%[.-m", "")
end

function export.escape(str)
  assert(type(str) == "string", "Invalid argument #1. Expected string, got " .. type(str))
  --TODO
  return str
end

function export.stringify(item, options)
  options = options or {}
  local opt = (options.state and options) or {}

  -- fist invocation, should parse options and setup state table
  if not opt.state then
    opt.state = {
      depth = 0,    -- keep track of the depth
      seen = { n = 0 }, -- avoid looping through endless references
    }

    -- parse options
    opt.depth = (type(options.depth) == "number" and options.depth > -2) or export.default_options.depth
    opt.table_len = (type(options.table_len) == "number" and options.table_len > -2) or export.default_options.table_len
    opt.string_len = (type(options.string_len) == "number" and options.string_len > -2) or
    export.default_options.string_len
    opt.colors = (type(options.colors) == "boolean") or export.default_options.colors
    opt.tab_width = (type(options.tab_width) == "number" and options.tab_width > 0) or export.default_options.tab_width
    opt.item_per_line = (type(options.item_per_line) == "number" and options.item_per_line > 0) or
    export.default_options.item_per_line
    opt.compact = (type(options.compact) == "boolean") or export.default_options.compact
    opt.escape = (type(options.escape) == "boolean") or export.default_options.escape
    opt.filter = (type(options.filter) == "function") or export.default_options.filter
  end

  return switch({
    ["function"] = dump_function,
    ["nil"] = dump_nil,
    ["boolean"] = dump_boolean,
    ["string"] = dump_string,
    ["number"] = dump_number,
    ["table"] = dump_table,
    ["thread"] = dump_thread,
    ["userdata"] = dump_userdata,
    ["default"] = dump_unknown -- should be never called, but idk, maybe some weird lua implementation...
  }):case(type(item))(item, opt)
end

function dump_string(item, options)
  local buff = item
  local truncated = 0

  if options.escape then
    buff = export.escape(buff)
  end

  if options.string_len > -1 and options.string_len < #buff then
    truncated = #buff - options.string_len
    buff = buff:sub(0, options.string_len)
  end

  local delim = options.colors and (export.default_colors.string .. "\"") or "\""

  if not options.state.key and truncated > 0 then
    buff = buff .. (options.colors and export.default_colors.syntax or "..") .. " .. " .. truncated .. " more"
  end

  if not options.state.key then
    buff = delim .. buff .. delim
  end

  if options.colors then buff = buff .. export.default_colors.stop end

  return buff
end

function dump_boolean(item, options)
  if options.colors and not options.state.key then
    return export.default_colors.boolean .. tostring(item) .. export.default_colors.stop
  else
    return tostring(item)
  end
end

function dump_number(item, options)
  if options.colors and not options.state.key then
    return export.default_colors.number .. tostring(item) .. export.default_colors.stop
  else
    return tostring(item)
  end
end

function dump_nil(item, options)
  if options.colors and not options.state.key then
    return export.default_colors["nil"] .. "nil" .. export.default_colors.stop
  else
    return "nil"
  end
end

local function handle_table(k, v, options)
  local colors = export.default_colors
  local buff = ""

  if options.state.seen[v] and (options.state.seen[v].depth <= options.state.depth or options.state.seen[v].tag) then
    local seen = options.state.seen[v]
    if not seen.tag then
      seen.tag = seen.tag or (options.state.seen.n + 1)
      options.state.seen.n = seen.tag
      return export.stringify(v, options) -- must update seen.pos
    end

    local tag = (options.colors and
          (colors.syntax .. "<" .. colors.number .. seen.tag .. colors.syntax .. ">" .. colors.stop)) or
        ("<" .. seen.tag .. ">")

    buff = (options.colors and
          (colors.builtin .. "[table" .. tag .. colors.builtin .. "]" .. colors.stop)) or
        ("[table" .. tag .. "]")
  else
    if type(v) == "table" then
      options.state.seen[v] = { tag = nil, depth = options.state.depth }
    end

    buff = export.stringify(v, options)
  end
  return buff
end

function dump_table(item, options)
  local colors = export.default_colors
  local depth = options.state.depth + 1
  options.state.depth = depth
  local size = table_size(item)
  local buff = (options.colors and (colors.syntax .. "{")) or "{"
  local i = 1

  if (options.depth > 0 and depth > options.depth) or options.state.key then
    local colrs = options.colors and not options.state.key
    options.state.depth = options.state.depth - 1
    return (colrs and
          (colors.builtin .. "[table" .. colors.syntax .. ":" .. colors.number .. size .. colors.builtin .. "]" .. colors.stop)) or
        ("[table:" .. size .. "]")
  end

  if depth == 1 then
    options.state.seen[item] = { tag = 1, depth = depth }
    options.state.seen.n = options.state.seen.n + 1
  end
  local temp = { key = {} }

  for k, v in pairs(item) do
    local skip = false
    if type(options.filter) == "function" then
      if options.filter(k, v) then
        skip = true
      else

      end
    end

    if not skip then
      local key_type = type(k)

      if temp.key[key_type] then
        table.insert(temp.key[key_type], k)
      else
        temp.key[key_type] = { k }
      end

      if type(v) == "table" then
        options.state.seen[v] = options.state.seen[v] or { tag = nil, depth = depth }
      end
    end
  end

  local item_per_line = options.item_per_line

  if temp.key["number"] then
    table.sort(temp.key["number"], function(a, b) return b > a end)

    for _, k in pairs(temp.key["number"]) do
      local v = item[k]

      if not options.compact and item_per_line >= options.item_per_line then
        buff = buff .. "\n" .. string.rep(" ", options.tab_width * depth)
        item_per_line = 1
      end
      if item_per_line >= options.item_per_line then -- items tracking
        item_per_line = 1
      else
        item_per_line = item_per_line + 1
      end

      local value = type(v) == "table" and handle_table(k, v, options) or export.stringify(v, options)
      local key_str = export.stringify(k,
        { depth = -1, colors = options.colors, escape = options.escape, state = { depth = 0, key = true } })


      if k > 0 then
        buff = buff .. value
      else
        buff = buff .. key_str .. (options.colors and (colors.syntax .. " = " .. value) or " = " .. value)
      end

      if i < size then
        buff = buff .. (options.colors and (colors.syntax .. ", ") or ", ")
      end

      i = i + 1
    end

    temp.key["number"] = nil
  end

  for key_type, key_value in pairs(temp.key) do
    for _, k in pairs(key_value) do
      local v = item[k]

      if not options.compact then
        buff = buff .. "\n" .. string.rep(" ", options.tab_width * depth)
      end

      local value = type(v) == "table" and handle_table(k, v, options) or export.stringify(v, options)
      local key_str = export.stringify(k,
        { depth = -1, colors = options.colors, string_len = options.string_len, escape = options.escape,
          state = { depth = 1, key = true } })

      buff = buff .. key_str .. (options.colors and (colors.syntax .. " = " .. value) or " = " .. value)

      if i < size then
        buff = buff .. (options.colors and (colors.syntax .. ", ") or ", ")
      end

      i = i + 1
    end
  end

  if not options.compact and size > 0 then
    buff = buff .. "\n" .. string.rep(" ", options.tab_width * (depth - 1))
  end

  buff = buff .. (options.colors and (colors.syntax .. "}") or "}")
  options.state.depth = depth - 1

  return buff
end

function dump_function(item, options)
  local buff = ""
  local infos = debug.getinfo(item)
  local colors = export.default_colors

  if not options.state.key then
    buff = (options.colors and colors.builtin or "") ..
    "[".. (infos.what == "C" and "C" or "") .."function" ..
    (options.colors and colors.syntax or "") ..
    ":" .. (options.colors and colors.number or "") .. infos.nparams .. (options.colors and colors.builtin or "") .. "]"

    if options.state.depth < 1 then
      local names = {}
    for i = 1, tonumber(infos.nparams) do
      local arg = debug.getlocal(item, i)
      if arg then
        table.insert(names, arg)
      end
    end
    local data = {
      name = infos.name or "",
      source = infos.short_src,
      args = infos.nparams,
      argsnames = names,
      type = infos.what
    }
    buff = buff .. export.stringify(data, options)
    end
  else
    return "[".. (infos.what == "C" and "C" or "") .."function:" .. infos.nparams .. "]"
  end

  return buff
end

function dump_thread(item, options)
  local colors = export.default_colors

  if options.colors and not options.state.key then
    return (colors.builtin .. "[thread]" .. colors.stop)
  else
    return "[thread]"
  end
end

function dump_userdata(item, options)
  local colors = export.default_colors

  if options.colors and not options.state.key then
    return (colors.builtin .. "[userdata]" .. colors.stop)
  else
    return "[userdata]"
  end
end

function dump_unknown(item, options)
  return tostring(item)
end

setmetatable(export, {
  __call = function(t, ...)
    return t.stringify(...)
  end
})

return export
