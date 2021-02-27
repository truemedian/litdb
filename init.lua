---# lit-glob #---
-- A file globbing library for Luvit.

--# Functions #--

local fs = require 'fs'

local function split(str)
    local parts, i = {}, 1

    for part in str:gmatch('([^\\/]+)') do
        parts[i] = part
        i = i + 1
    end

    return parts
end

local quotepattern = '([' .. ("%^$().[]*+-?"):gsub("(.)", "%%%1") .. '])'
local function escape(str) return (str:gsub(quotepattern, "%%%1")) end

local patt_any_one = '[^/\\]'
local patt_any = patt_any_one .. '*'
local patt_globstar = '.*'

local function compile_individual(str)
    local parts = {}

    local star
    local pos = 1
    while pos <= #str + 1 do
        local char = str:sub(pos, pos)

        if char == '*' then
            if not star then star = pos end
        elseif char == '?' then
            table.insert(parts, patt_any_one)
        elseif char == '[' then
            local stop = str:find(']', pos, true)

            local inside = escape(str:sub(pos + 1, stop - 1))
            if inside:sub(1, 1) == '!' then
                inside = '^' .. inside:sub(2)
            end

            table.insert(parts, '[' .. inside .. ']')

            pos = stop
        elseif star then
            local n = pos - star

            if n == 1 then
                table.insert(parts, patt_any)
            elseif n == 2 then
                table.insert(parts, patt_globstar)
            else
                return error('could not compile glob: unknown star pattern: ' ..
                                 string.rep('*', n))
            end

            star = nil

            table.insert(parts, escape(char))
        else
            table.insert(parts, escape(char))
        end

        pos = pos + 1
    end

    return table.concat(parts)
end

--- @function compile :: str:string -> pattern:string
--- Compiles a glob string into a Lua pattern for use in matching files.
local function compile(str)
    local parts = split(str)

    for i, part in ipairs(parts) do parts[i] = compile_individual(part) end

    return table.concat(parts, '/')
end

local function exhaustive_find(str, pattern)
    local start, stop = str:find(pattern)
    return start == 1 and stop == #str
end

local function readdir_aux(path, accum, pattern)
    for name, kind in fs.scandirSync(path) do
        local file = path .. '/' .. name

        if exhaustive_find(file, pattern) then table.insert(accum, file) end

        if kind == 'directory' then readdir_aux(file, accum, pattern) end
    end
end

--- @function readdir :: dir:string, glob:string -> files:table
--- Iterates recursively over `dir` and returns a table of all files matching `glob`.
local function readdir(dir, glob)
    local pattern = compile(dir .. '/' .. glob)

    local files = {}
    readdir_aux(dir, files, pattern)

    return files
end

local function scandir_aux(path, pattern)
    for name, kind in fs.scandirSync(path) do
        local file = path .. '/' .. name

        if exhaustive_find(file, pattern) then
            coroutine.yield(file, kind)
        end

        if kind == 'directory' then scandir_aux(file, pattern) end
    end
end

local function scandir_wrap(path, pattern)
    coroutine.yield()

    scandir_aux(path, pattern)
end

--- @function scandir :: dir:string, glob:string -> iterator:function
--- An iterator which will iterate recursively over `dir` and return the `path` and `kind` of each matching file.
-- This is intended for use in `for path, kind in` statements, but may be used individually.  
-- `path` will be relative to `dir.  
-- `kind` will be one of `file`, `directory`, or any other possible file type.
local function scandir(dir, glob)
    local pattern = compile(dir .. '/' .. glob)

    local wrapped = coroutine.wrap(scandir_wrap)
    wrapped(dir, pattern)

    return wrapped
end

--- @function match_baseless :: file:string, glob:string -> matches:boolean
--- Checks if `file` matches `glob`.
local function match_baseless(file, glob)
    return exhaustive_find(file, compile(glob))
end

--- @function match :: dir:string, file:string, glob:string -> matches:boolean
--- Checks if `file` matches `glob` after prepending `dir`.
-- `file` should be a path starting with `dir`.
local function match(dir, file, glob)
    return exhaustive_find(file, compile(dir .. '/' .. glob))
end

return {
    compile = compile,
    readdir = readdir,
    scandir = scandir,
    match = match,
    match_baseless = match_baseless
}
