--[[
    Multi-file loader, designed to load all modules in a directory and return them as one table.
    Mostly intended as a way to load separate simple scripts, such as for use as commands in a chat bot.

    --[=[ License terms:

        MIT License

        Copyright (c) 2018 Aaron Knott

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
    version = "2.0.1"
    license = "MIT"
    homepage = "https://github.com/Samur3i/direct-loader"
    dependencies = {
        "luvit/require",
        "luvit/fs"
    }
--]]

local fs = require("fs")

local exports = {}
local handlers = {}

--[[
    Function to merge all values from a key conflict into a single table, giving them a key that is the same as
    the script the function was loaded from.

    For example:
    Given two scripts, foo.lua and bar.lua, each with a function func(), the result would be the table "func"
    containing the functions foo() and bar().
    In this way, all functions can be included regardless of the number of conflicts, as no two scripts in a single
    directory should be able to share the exact same name.
--]]
function handlers.merge(_, newValue, storedValue, metadata)
    local mergedTable = {}
    if type(storedValue) == "table" and metadata.merged then
        -- The key has already been merged; simply add the new value to the table.
        mergedTable = storedValue
        mergedTable[metadata.currentSource] = newValue
    else
        -- Create a new merged table, storing the current and new values using their source as the key.
        metadata.merged = true
        mergedTable[metadata.originalSource] = storedValue
        mergedTable[metadata.currentSource] = newValue
    end
    return mergedTable
end

-- Function that replaces previous values with subsequently-encountered ones.
function handlers.replace(_, newValue)
    return newValue
end

--[[
    Function to load all files from a directory, and compress them into one table.
    Uses Luvit's File System library for I/O operations, rather than the standard io library.

    This function accepts two arguments: a filepath to a directory, and the method in which to handle conflicts.
    The only required argument is the first one; when not supplied with a conflict handler, conflicts will simply be
    ignored, preserving only the first value of that name that was encountered.
    If a conflict handler is desired, one can be defined in one of two ways: as a string naming a default handler,
    or as a custom function.
    If a custom function is used, then it must abide by the rules defined in the docs, or the resulting behavior may
    be unpredictable.
--]]
function exports.load(path, conflictHandler)
    if type(path) ~= "string" then
        return nil, "Unexpected type to argument #1 (string expected, got "..type(path)..")\n"
    else
        -- Check if path leads to a directory:
        local stat = fs.statSync(path)
        if not stat or stat.type ~= "directory" then
            return nil, "No such directory: "..path.."\n"
        end
    end
    local doHandleConflicts = true -- Assign as true, since only one case leads to it being false.
    if not conflictHandler then
        -- If conflictHandler is false or nil, then conflicts will be ignored.
        doHandleConflicts = false
    elseif type(conflictHandler) == "string" then
        if handlers[conflictHandler] then
            -- Assign the corresponding function
            conflictHandler = handlers[conflictHandler]
        else
            -- The string was not a valid handler; return nil.
            return nil, conflictHandler.." is not a valid conflict handler\n"
        end
    elseif type(conflictHandler) ~= "function" then
        return nil, "Unexpected type to argument #2 (string or function expected, got "..type(conflictHandler)..")\n"
    end

    local modules = {} -- Table to store the results from each require in.

    io.write("Loading files from directory: "..path.."\n")
    for fname, ftype in fs.scandirSync(path) do
        -- Iterate through the files in the given directory, loading Lua files
        if ftype == "file" and fname:find("%.lua") then
            -- Build the require path by stripping the extension from the filename using string.match,
            -- then attempt to require the module using that path in a protected call:
            local name = fname:match("(.+)%.lua")
            local success, result = pcall(require, path.."/"..name)
            if success then
                io.write("Loaded "..fname.."\n")
                modules[name] = result -- Save with name as key to aid with resolving conflicts.
            else
                io.write("Failed to load "..fname.." with error: "..result.."\n")
            end
        end
    end
    if next(modules) == nil then
        -- Nothing was loaded. Return nil since continuing would be pointless.
        return nil, "No modules loaded from directory: "..path.."\n"
    end

    local target = {} -- Table to build into. This will be the return value of the function.
    local metadata = {} -- Store metadata, such as what a certain key conflicts with.
    local numConflicts = 0 -- Store the number of conflicts encountered while merging the tables.

    -- Protect the following keys for use in metadata:
    local restrictedKeys = {originalSource = true, currentSource = true, lastSource = true, sources = true}

    -- Function to be used as the __newindex metamethod for metadata proxy tables.
    -- Protects certain keys to prevent conflictHandler functions from overwriting them by mistake.
    local function safeWrite(tbl, key, value)
        local index = getmetatable(tbl).__index
        if restrictedKeys[key] then
            error("Attempt to overwrite a protected key.", 2)
        else
            index[key] = value
        end
    end

    for source, module in pairs(modules) do
        -- Take the loaded modules, and begin building the new table.
        if type(module) == "table" then
            for key, value in pairs(module) do
                if target[key] == nil then
                    target[key] = value
                    metadata[key] = {
                        originalSource = source, -- Where the key was first encountered.
                        currentSource = source, -- The source in the current loop.
                        lastSource = source, -- The previous source in the loop.
                        sources = {source}, -- Everywhere the key has been encountered.
                    }
                else
                    -- Log the conflict:
                    io.write(string.format("The key [%s] already exists: %s and %s have conflicting entries.\n",
                            key, metadata[key].lastSource, source))
                    -- Now update the metadata and handle the conflict if a handler was provided:
                    numConflicts = numConflicts + 1
                    metadata[key].lastSource = metadata[key].currentSource
                    metadata[key].currentSource = source
                    table.insert(metadata[key].sources, source)
                    if doHandleConflicts and conflictHandler then
                        --[[
                            Call conflictHandler in a protected call, passing the conflicting key,
                            the newly-conflicted value, the current value in the target table, and a proxy for the
                            current key's metadata.

                            By using a proxy table with __index and __newindex metamethods, we can access and assign
                            or edit values from an external function, without needing to return the edited metadata
                            table from it.

                            Metatables are certainly useful.
                        --]]
                        local proxy = setmetatable({}, {__index = metadata[key], __newindex = safeWrite})
                        local success, result = pcall(conflictHandler, key, value, target[key], proxy)
                        if success then
                            target[key] = result
                        else
                            io.write("Failed to resolve conflict with error: "..result.."\n")
                            -- TODO: Should anything else be done if conflict resolution fails?
                        end
                    end
                end
            end
        end
    end
    io.write("Encountered "..numConflicts.." conflict(s) while combining tables.\n")
    return target
end

return exports
