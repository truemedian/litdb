local sql = require 'sqlite3'
local config = require './config'
local conn = sql.open 'invicta.db'

conn:exec([[
CREATE TABLE IF NOT EXISTS guild_settings (
	guild_id TEXT PRIMARY KEY,
	prefix TEXT DEFAULT "]] .. config.prefix .. [["
)
]])