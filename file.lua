--[[lit-meta
    name = "Richy-Z/logger"
    version = "1.0.5"
    dependencies = {"luvit/fs"}
    description = "A lightweight per-instance logging utility"
    tags = { "logger", "logs", "logging", "stdout", "error" }
    license = "Apache 2.0"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

--[[
Portions of this file are based on "Logger" by SinisterRectus
It was originally licensed under the MIT license
https://github.com/SinisterRectus/Discordia/blob/master/libs/utils/Logger.lua

Modifications made in this version:
- Rewrote into a stateless design, allowing multiple logger instances
  even when using Lua’s require() caching
- Added shortcut methods (:error, :info, :debug, :p, etc.) for convenience
]]

local fs                  = require("fs")

local date                = os.date
local format              = string.format
local stdout              = _G.process.stdout.handle ---@diagnostic disable-line: undefined-field
local openSync, writeSync = fs.openSync, fs.writeSync

local RED                 = 31
local GREEN               = 32
local YELLOW              = 33
local CYAN                = 36

local config              = {
    { "[ERROR]  ", RED },
    { "[WARNING]", YELLOW },
    { "[INFO]   ", GREEN },
    { "[DEBUG]  ", CYAN },
}

-- precompute coloured tags
do
    local bold = 1
    for _, v in ipairs(config) do
        v[3] = format("\27[%d;%dm%s\27[0m", bold, v[2], v[1])
    end
end

local levels = {
    none    = 0,
    error   = 1,
    warning = 2,
    info    = 3,
    debug   = 4,
}

-- Creates a new per-instance logger that prints formatted messages to both stdout and an optional log file.
--
-- - string `levelName`: Minimum log level to show. One of `"none"`, `"error"`, `"warning"`, `"info"`, or `"debug"`. Defaults to `"warning"` if invalid.
-- - string `dateTimeFormat`: An optional format string accepted by `os.date`, e.g. `""!%Y-%m-%d %H:%M:%S"` for UTC timestamps.
-- - string `filePath`: Optional path to a file where logs should also be written, without any of the ANSI colour codes / highlighting, etc.
--
-- This should return your new instance which will include the shortcut methods below:
--
-- ```lua
-- logger:error(msg, ...)   -- level 1
-- logger:warning(msg, ...) -- level 2
-- logger:info(msg, ...)    -- level 3
-- logger:debug(msg, ...)   -- level 4
-- logger:p(msg, ...)       -- level 0, always logs (useful for prints)
-- ```
---@param levelName ("none" | "error" | "warning" | "info" | "debug")
---@param dateTimeFormat? string
---@param filePath? string
---@return table
local function main(levelName, dateTimeFormat, filePath)
    local level = levels[levelName] or levels.warning
    local logFile = filePath and openSync(filePath, "a")

    local function log(logLevel, msg, ...)
        if level < logLevel then return end

        local tag = config[logLevel]
        if not tag then return end

        msg = format(msg, ...)

        local timestamp = date(dateTimeFormat)
        local formatted = format("%s | %s | %s\n", timestamp, tag[3], msg)

        stdout:write(formatted)

        if logFile then
            local rawTag = tag[1] -- no ANSI
            local fileLine = format("%s | %s | %s\n", timestamp, rawTag, msg)
            writeSync(logFile, -1, fileLine)
        end

        return msg
    end

    return {
        log = log,
        error = function(_, msg, ...) return log(1, msg, ...) end,
        warning = function(_, msg, ...) return log(2, msg, ...) end,
        info = function(_, msg, ...) return log(3, msg, ...) end,
        debug = function(_, msg, ...) return log(4, msg, ...) end,
        p = function(_, msg, ...) return log(0, msg, ...) end,
    }
end

return main
