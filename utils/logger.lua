local fs = require('fs')
local writeSync = fs.writeSync

local stdout = process.stdout.handle
local stderr = process.stderr.handle

local f = string.format

local RED     = 31
local GREEN   = 32
local YELLOW  = 33
local CYAN    = 36

local config = {
	{'ERROR', RED},
	{'WARNING', YELLOW},
	{'INFO', GREEN},
	{'DEBUG', CYAN},
}

for _, v in ipairs(config) do
   v[2] = f('\27[%sm', v[2])
end

local function log(self, level, msg, ...)
   if self._level < level then return end

   local tag = config[level]
   if not tag then return end

   msg = f(msg, ...)

   local d = os.date(self._dateTime)

   if self._file then
      writeSync(self._file, -1, f('%s - %s: %s\n', d, tag[1], msg))
   end

   local to = level == 1 and stderr or stdout

   to:write(f('%s%s  %s %s: %s%s\n', tag[2], d, os.date('%H:%S', os.time() - self._startTime), tag[1], msg, '\27[0m'))

   return msg
end

return log