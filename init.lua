local pp = require('pretty-print')
local sys = require('ffi').os
local print
print = pp.print
local format
format = function(str, vars)
  if not vars then
    return str
  end
  local f
  f = function(x)
    return tostring(vars[x] or vars[tonumber(x)] or "{" .. tostring(x) .. "}")
  end
  return (str:gsub("{(.-)}", f))
end
local checkpath
checkpath = function()
  if sys == 'Windows' or require('ffi').os == 'Windows' then
    return '\\'
  else
    return '/'
  end
end
local split
split = function(s, delimiter)
  local result = { }
  for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end
local N34T
do
  local _class_0
  local _base_0 = {
    add = function(self, filename, variables)
      if variables then
        self.LOGFILE = format(filename, variables)
      else
        self.LOGFILE = filename
      end
    end,
    remove = function(self)
      os.remove(self.LOGFILE)
      self.LOGFILE = nil
    end,
    trace = function(self, ...)
      if self.LEVELS['trace'] < self.LEVELS[self.LEVEL] then
        return 
      end
      local m = ...
      local pat = { }
      local deb = debug.getinfo(2, 'Sl')
      local p = split(deb.short_src, checkpath())
      table.insert(pat, p[#p - 1])
      table.insert(pat, p[#p])
      pat = table.concat(pat, '/')
      local line = pat .. ':' .. deb.currentline
      print(format('{date} |  {level} | {message}', {
        ['date'] = tostring(pp.color('quotes')) .. tostring(os.date('%c')) .. tostring(pp.color('property')),
        ['level'] = tostring(pp.color('userdata')) .. "TRACE" .. tostring(pp.color('property')),
        ['message'] = tostring(pp.color('table')) .. tostring(line) .. tostring(pp.color('property')) .. " - " .. tostring(pp.color('userdata')) .. tostring(m or ...) .. tostring(pp.color('property'))
      }))
      if self.LOGFILE then
        do
          local _with_0 = io.open(self.LOGFILE, 'a')
          _with_0:write(tostring(os.date('%c')) .. " |  TRACE | " .. tostring(m or ...) .. "\n")
          _with_0:close()
          return _with_0
        end
      end
    end,
    info = function(self, ...)
      if self.LEVELS['info'] < self.LEVELS[self.LEVEL] then
        return 
      end
      local m = ...
      local pat = { }
      local deb = debug.getinfo(2, 'Sl')
      local p = split(deb.short_src, checkpath())
      table.insert(pat, p[#p - 1])
      table.insert(pat, p[#p])
      pat = table.concat(pat, '/')
      local line = pat .. ':' .. deb.currentline
      print(format('{date} |  {level}  | {message}', {
        ['date'] = tostring(pp.color('quotes')) .. tostring(os.date('%c')) .. tostring(pp.color('property')),
        ['level'] = tostring(pp.color('string')) .. "INFO" .. tostring(pp.color('property')),
        ['message'] = tostring(pp.color('table')) .. tostring(line) .. tostring(pp.color('property')) .. " - " .. tostring(pp.color('string')) .. tostring(m or ...) .. tostring(pp.color('property'))
      }))
      if self.LOGFILE then
        do
          local _with_0 = io.open(self.LOGFILE, 'a')
          _with_0:write(tostring(os.date('%c')) .. " |  INFO  | " .. tostring(m or ...) .. "\n")
          _with_0:close()
          return _with_0
        end
      end
    end,
    warn = function(self, ...)
      if self.LEVELS['warn'] < self.LEVELS[self.LEVEL] then
        return 
      end
      local m = ...
      local pat = { }
      local deb = debug.getinfo(2, 'Sl')
      local p = split(deb.short_src, checkpath())
      table.insert(pat, p[#p - 1])
      table.insert(pat, p[#p])
      pat = table.concat(pat, '/')
      local line = pat .. ':' .. deb.currentline
      print(format('{date} |  {level}  | {message}', {
        ['date'] = tostring(pp.color('quotes')) .. tostring(os.date('%c')) .. tostring(pp.color('property')),
        ['level'] = tostring(pp.color('boolean')) .. "WARN" .. tostring(pp.color('property')),
        ['message'] = tostring(pp.color('table')) .. tostring(line) .. tostring(pp.color('property')) .. " - " .. tostring(pp.color('boolean')) .. tostring(m or ...) .. tostring(pp.color('property'))
      }))
      if self.LOGFILE then
        do
          local _with_0 = io.open(self.LOGFILE, 'a')
          _with_0:write(tostring(os.date('%c')) .. " |  WARN  | " .. tostring(m or ...) .. "\n")
          _with_0:close()
          return _with_0
        end
      end
    end,
    error = function(self, ...)
      if self.LEVELS['error'] < self.LEVELS[self.LEVEL] then
        return 
      end
      local m = ...
      local pat = { }
      local deb = debug.getinfo(2, 'Sl')
      local p = split(deb.short_src, checkpath())
      table.insert(pat, p[#p - 1])
      table.insert(pat, p[#p])
      pat = table.concat(pat, '/')
      local line = pat .. ':' .. deb.currentline
      print(format('{date} |  {level} | {message}', {
        ['date'] = tostring(pp.color('quotes')) .. tostring(os.date('%c')) .. tostring(pp.color('property')),
        ['level'] = tostring(pp.color('thread')) .. "ERROR" .. tostring(pp.color('property')),
        ['message'] = tostring(pp.color('table')) .. tostring(line) .. tostring(pp.color('property')) .. " - " .. tostring(pp.color('thread')) .. tostring(m or ...) .. tostring(pp.color('property'))
      }))
      if self.LOGFILE then
        do
          local _with_0 = io.open(self.LOGFILE, 'a')
          _with_0:write(tostring(os.date('%c')) .. " |  ERROR | " .. tostring(m or ...) .. "\n")
          _with_0:close()
          return _with_0
        end
      end
    end,
    fatal = function(self, ...)
      if self.LEVELS['fatal'] < self.LEVELS[self.LEVEL] then
        return 
      end
      local m = ...
      local pat = { }
      local deb = debug.getinfo(2, 'Sl')
      local p = split(deb.short_src, checkpath())
      table.insert(pat, p[#p - 1])
      table.insert(pat, p[#p])
      pat = table.concat(pat, '/')
      local line = pat .. ':' .. deb.currentline
      print(format('{date} |  {level} | {message}', {
        ['date'] = tostring(pp.color('quotes')) .. tostring(os.date('%c')) .. tostring(pp.color('property')),
        ['level'] = tostring(pp.color('err')) .. "FATAL" .. tostring(pp.color('property')),
        ['message'] = tostring(pp.color('table')) .. tostring(line) .. tostring(pp.color('property')) .. " - " .. tostring(pp.color('err')) .. tostring(m or ...) .. tostring(pp.color('property'))
      }))
      if self.LOGFILE then
        do
          local _with_0 = io.open(self.LOGFILE, 'a')
          _with_0:write(tostring(os.date('%c')) .. " |  FATAL | " .. tostring(m or ...) .. "\n")
          _with_0:close()
          return _with_0
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, level)
      if level == nil then
        level = 'trace'
      end
      self.COLORSTHEME = theme
      self.LEVEL = level
      pp.loadColors(pp.theme[256])
      self.LEVELS = {
        ['trace'] = 1,
        ['info'] = 2,
        ['warn'] = 3,
        ['error'] = 4,
        ['fatal'] = 5
      }
    end,
    __base = _base_0,
    __name = "N34T"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  N34T = _class_0
end
N34T._VERSION = '2.0.0'
N34T._AUTHOR = 'mrtnpwn'
return N34T
