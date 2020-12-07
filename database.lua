---@type sqlite3
local sqlite = require 'sqlite3'

local conn = sqlite.open 'db.sqlite'

conn:exec [[
CREATE TABLE IF NOT EXISTS users (
   UserId TEXT NOT NULL PRIMARY KEY, 
   Xp REAL DEFAULT 0, 
   Config TEXT DEFAULT "
edit '--// Blank notepad \\--'

editor:addCommand('rep', function(args)
   local repeated = ''

   local toRepeat = args[1]
   local count = tonumber(args[2])

   if not count then
   return editor:reject('Invalid count')
   end

   for i = 1, count do
   repeated = repeated .. toRepeat
   end

   editor:editCurrentLine(repeated)
end)
");
]]

local function get(tbl, idName, id)
   local stmt = conn:prepare("SELECT * FROM " .. tbl .. " WHERE " .. idName .. " = ?;")

   return stmt:reset():bind(id):step()
end

return {
   conn = conn,
   get = get
}