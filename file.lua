--[[
    Multi-file loader, designed to load all modules in a directory and return them as one table.
    Mostly intended as a way to load separate simple scripts, such as for use as commands in a chat bot.

    --[=[ License terms:

        MIT License

        Copyright (c) 2018—2021 Aaron Knott

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.

    --]=]
--]]
--[[lit-meta
    name = "Samur3i/direct-loader"
    version = "3.0.0"
    license = "MIT"
    homepage = "https://github.com/Samur3i/direct-loader"
    dependencies = {
        "luvit/require",
        "luvit/fs"
    }
--]]

local fs = require("fs")
local exports = {}

-- Store commonly-used built-in functions in local variables to speed up function access.
-- This helps execution speed by cutting down on global table lookups during long for loops.
local write = io.write
local insert = table.insert

-- Function to merge all values from a key conflict into a single table, giving them a key that is the same as the script the function was loaded from.
local function merge(key, newValue, storedValue, metadata)
    local mergedTable = {}
    write("Attempting to merge key ["..key.."]...\n")
    if type(storedValue) == "table" and metadata.__merged then
        -- The key has already been merged, so add the new value to the table.
        mergedTable = storedValue
        if not mergedTable[metadata.__currentSource] then
            mergedTable[metadata.__currentSource] = newValue
            write("The key ["..key.."] was previously merged. Adding the new value to the table...\n")
        else
            error("Unexpected error during conflict resolution: the entry ["..metadata.__currentSource.."] already exists in the merged table")
        end
    else
        -- Create a new merged table, storing the current and new values using their source as the key.
        write("Creating a new merged table for key ["..key.."]\n")
        mergedTable[metadata.__originalSource] = storedValue
        mergedTable[metadata.__currentSource] = newValue
        metadata.__merged = true
    end
    return mergedTable
end

-- Function to load all files from a directory, and compress them into one table. Uses Luvit's File System library for file operations.
function exports.load(path, conflictHandler)
    if type(path) ~= "string" then
        return nil, "Unexpected type to argument #1 (string expected, got "..type(path)..")\n"
    else
        -- Check if the given path leads to a directory:
        local stat = fs.statSync(path)
        if not stat or stat.type ~= "directory" then
            return nil, "No such directory: "..path.."\n"
        end
    end
    if type(conflictHandler) ~= "function" then
        if type(conflictHandler) ~= "nil" then
            -- Log a warning about expected types.
            write("Unexpected type to argument #2 (function or nil expected, got "..type(conflictHandler)..")\n")
        end
        conflictHandler = merge
        write("A valid custom handler was not provided. Defaulting to the built-in handler.\n")
    else
        write("Conflicts will be handled using the provided handler.\n")
    end

    local modules = {} -- Table to store the results from each require in.
    local numModules = 0 -- The number of modules loaded from the given directory.

    write("Loading files from directory: "..path.."\n")
    for fname, ftype in fs.scandirSync(path) do
        -- Iterate through the files in the given directory, loading Lua files.
        if ftype == "file" and fname:find("%.lua") then
            -- Build the require path by stripping the extension from the filename using string.match, then attempt to require the module using that path in a protected call.
            local name = fname:match("(.+)%.lua")
            local success, result = pcall(require, path.."/"..name)
            if success then
                write("Successfully loaded "..fname.."\n")
                modules[name] = result -- Save with name as key to aid with resolving conflicts.
                numModules = numModules + 1
            else
                write("Failed to load "..fname.." with error: "..result.."\n")
            end
        end
    end

    if next(modules) == nil then
        -- Nothing was loaded. Return nil since continuing would be pointless.
        return nil, "No modules loaded from directory: "..path.."\n"
    end

    local target = {}       -- Table to build into. This will be the return value of the function.
    local metadata = {}     -- Store metadata, such as what a certain key conflicts with.
    local numConflicts = 0  -- Store the number of conflicts encountered while merging the tables.
    local numHandled = 0    -- Store the number of conflicts that were successfully handled.

    -- Protect the following keys for use in metadata:
    local restrictedKeys = {__originalSource = true, __currentSource = true, __lastSource = true, __sources = true}

    -- Function to be used as the __newindex metamethod for metadata proxy tables.
    -- Protects certain keys to prevent custom conflict handlers from overwriting important metadata by mistake.
    -- If someone really wanted to, they can circumvent this, of course. We just want to prevent accidental overwriting.
    local function safeWrite(tbl, key, value)
        if restrictedKeys[key] then
            -- Throw an error warning whatever function attempted to overwrite the metadata not to do that.
            error("Unauthorized table access: attempt to overwrite a protected key", 2)
        else
            -- Fetch the real metadata table and assign the new value.
            local realMetadata = getmetatable(tbl).__index
            realMetadata[key] = value
        end
    end

    -- Function to check if a key conflicts with any other key before adding it the list of functions to be exported.
    local function exportFunction(source, value, key)
        key = key or source -- If no value for key was passed in, key == source.

        if target[key] == nil then
            target[key] = value
            metadata[key] = {
                __originalSource = source,  -- Where the key was first encountered.
                __currentSource = source,   -- The source in the current loop.
                __lastSource = source,      -- The previous source in the loop.
                __sources = {source},       -- Everywhere the key has been encountered.
            }
        else
            write("The key ["..key.."] already exists in the export table. Attempting to handle the conflict...\n")
            numConflicts = numConflicts + 1

            -- Update the metadata for the current key to reflect the conflict.
            -- To do this, we set __lastSource to the current value of __currentSource, then set __currentSource to the current value of source.
            -- Additionally, we use table.insert to add the value of source to __sources, so that we can know everywhere it has appeared.
            metadata[key].__lastSource = metadata[key].__currentSource
            metadata[key].__currentSource = source
            insert(metadata[key].__sources, source)

            -- Now, rather than pass the metadata table in directly, we create a proxy table and set the __index and __newIndex metamethods.
            -- This prevents custom conflict handlers from overwriting important metadata by mistake, while still allowing them to write custom metadata.
            -- Additionally, the conflict handler is called in a protected call, which is done for two reasons.
            -- Firstly, so that safeWrite can throw an error if the function attempts to overwrite important metadata, which will stop the handler from doing anything else.
            -- Secondly, it's the simplest way of allowing a custom handler to say it can't handle a conflict; all it has to do is throw an error.
            local proxy = setmetatable({}, {__index = metadata[key], __newindex = safeWrite})
            local success, result = pcall(conflictHandler, key, value, target[key], proxy)
            if success then
                target[key] = result
                numHandled = numHandled + 1
                write("Successfully handled conflict with key ["..key.."]\n")
                return true
            else
                write("Failed to resolve conflict with error: "..result.."\n")
                return false
            end
        end
    end

    for source, module in pairs(modules) do
        if type(module) == "table" then
            for key, value in pairs(module) do
                exportFunction(source, value, key)
            end
        elseif type(module) == "function" then
            exportFunction(source, module)
        end
    end

    write("Encountered "..numConflicts.." conflict(s) while loading "..numModules.." module(s).\n", "Out of "..numConflicts.." conflict(s), "..numHandled.." were successfully handled.\n")
    return target, nil, metadata
end

return exports
