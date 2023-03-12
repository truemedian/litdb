--[[lit-meta
name = "UrNightmaree/redotenv"
version = "0.1"
dependencies = {}
description = "An optimized .env parser for Lua"
tags = { "lua", "lit", "luvit", "dotenv", "parser" }
license = "MIT"
author = { name = "UrNightmaree", email = "afiqquraisyzulkarnain@gmail.com" }
homepage = "https://github.com/UrNightmaree/redotenv.lua"
]]

local open = io.open

---@param func string
---@param tbl table
local function check_arg(func,tbl)
    local argc = 1
    for i = 1,#tbl,2 do
        if type(tbl[i]) ~= tbl[i+1] then
            error(
            ("bad argument #%d to '%s' (%s expected, got %s)"):format(
            argc, func, tbl[i+1], type(tbl[i]))
            )
        end
        argc = argc + 1
    end
end

--[[
Parse a string which contains .env code. Return a table of parsed string if success, otherwise return nil + error message.
]]
---@param src string
---@return table?
---@return string?
local function redotenv_parse(src)
    check_arg("parse",{
        src, "string"
    })

    local tbl = {}
    local err
    for l in src:gmatch "([^\n]+)" do
        l = l.."\n" -- Add indicator for EOL
        l = l:gsub("#.-\n","")

        if l == "" or l:match "^%s+$" then
            goto continue
        end

        local k, is_v
        for s in l:gmatch "([^=]+)" do
            if not is_v and s:match "^%w+$" then
                k = s
            elseif is_v and k:match "^%w+$" then
                tbl[k] = s
            else
                err = "expected captured '^%w+$' pattern, got "..s
                break
            end
            is_v = true
        end
        ::continue::
    end

    if err then
        return nil, err
    else return tbl end
end

--[[
Load and parse a file, defaults to `.env`. Return parsed table if success, otherwise return nil + error message.
]]
---@param filename string?
---@return table?
---@return string?
local function redotenv_load(filename)
    filename = filename or "./.env"

    check_arg("load",{
        filename, "string"
    })

    local f, open_err = open(filename,'r')
    if not f and open_err then
        return nil, open_err
    end

    ---@diagnostic disable-next-line:need-check-nil
    local parsed_tbl, parse_err = redotenv_parse(f:read "*a")
    ---@diagnostic disable-next-line:need-check-nil
    f:close()

    if not parsed_tbl and parse_err then
        return nil, parse_err
    end

    return parsed_tbl
end

return {
    parse = redotenv_parse,
    load = redotenv_load,
    _VERSION = "redotenv 0.1"
}
