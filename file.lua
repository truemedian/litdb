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
    version = "1.3.0"
    license = "MIT"
    homepage = "https://github.com/Samur3i/direct-loader"
    dependencies = {
        "luvit/fs"
    }
--]]

local export = {}
local fs = require("fs")

local DEFAULT_METHOD = "merge"
local VALID_METHODS = {
    -- Makes arg-checking easier.
    merge = true, 
    ignore = true,
    rename = true,
    replace = true
}

local function isDir(path)
    -- Helper function to verify a given path leads to a directory. Returns true or false.
    local stat = fs.statSync(path)
    if not stat then
        -- Path is invalid; return false.
        return false
    else
        return stat.type == "directory"
    end
end

function export.getDefaultBehavior()
    -- Returns the current default behavior.
    return DEFAULT_METHOD
end

function export.setDefaultBehavior(newDefault)
    -- Function to change the default conflict behavior of load().
    -- Returns true on success, false and an error on failure.
    if type(newDefault) ~= "string" then
        return false, string.format("Unexpected type to argument #1 (string expected, got %s)", type(newDefault))

    elseif not VALID_METHODS[newDefault] then
        return false, string.format("Unexpected value \"%s\" to argument #1", newDefault)
    else
        DEFAULT_METHOD = newDefault
        return true
    end
end

function export.load(path, conflictBehavior)
    --[[ 
        Function to load all scripts from a given directory, then return the results from them as one table.
        Returns the new table on success, nil and an error on failure.

        Defining conflictBehavior is optional, and defaults to "merge", though this can be changed at runtime with setDefaultMethod().
        When set to "merge", this function will merge conflicted entries into a table named <key> containing the duplicate keys' values.
        They are named such that, given two modules foo and bar, each containing the function func(), the result would be the table func containing the functions foo() and bar().

        In addition to merge, the other optional modes are "ignore", "rename", and "replace".
        - Using "ignore" will cause all conflicts to be ignored, saving only the first value assigned.
        - Using "rename" will cause all keys to be renamed, such that function func() from script foo would become foo_func().
        - Using "replace" will cause conflicting values to be overwritten by each subsequent value, such that the last conflicting value parsed will be the one assigned.

        Certain methods are unreliable due to the way that the pairs() function works, meaning that the same value nor order can not be guaranteed across multiple calls.

        Regardless of the behavior chosen, this function will log all conflicts.
    --]]

    if type(path) ~= "string" then
        return nil, string.format("Unexpected type to argument #1 (string expected, got %s)", type(path))
    elseif not isDir(path) then
        return nil, "No such directory: "..path
    end

    conflictBehavior = conflictBehavior or DEFAULT_METHOD
    if type(conflictBehavior) ~= "string" then
        return nil, string.format("Unexpected type to argument #2 (string expected, got %s)", type(conflictBehavior))

    elseif not VALID_METHODS[conflictBehavior] then
        return nil, string.format("Unexpected value \"%s\" to argument #2", conflictBehavior)
    end
    
    local write, format, insert = io.write, string.format, table.insert -- Localize looped functions to improve performace in large loops.
    local modules = {} -- Table to store the results from each require in.
    local originalSource = {} -- Create an empty table to store metadata in.

    write(format("Loading files from directory: %s\n", path))
    for fname, ftype in fs.scandirSync(path) do
        if ftype == "file" and fname:find("%.lua") then
            -- Build the require path by stripping the extension from the filename using string.match()
            -- Then attempt to require the module using that path in a protected call.
            local name = fname:match("(.+)%.lua")
            local scriptPath = format("%s/%s", path, name)
            local success, result = pcall(require, scriptPath)
            if not success then
                -- If the require failed, log the error and move on.
                write(format("Failed to load %s.lua with error:\n%s\n", name, result))
            else
                write(format("Loaded %s.lua\n", name))
                modules[name] = result
            end
        end
    end
    if next(modules) == nil then
        -- Nothing was returned. Return nil since continuing would be pointless.
        return nil, "No modules loaded from directory: "..path
    end

    -- Begin building the new table:
    local target = {} -- Create an empty table to build into.
    local numConflicts = 0 -- Store the number of conflicts encountered while merging the tables.
    local mergedTables = {} -- Store an index of merged tables so that metadata can be removed once the new table is complete.

    write("Building new table from loaded modules...\n")
    for source, module in pairs(modules) do
        -- Iterates through the provided table, looking for nested tables or top-level functions.
        -- Upon finding a nested table, iterate through it, adding everything in that table to the new, combined table.
        if type(module) == "table" then
            -- First, check if source has any dashes or spaces, and replace them with underscores.
            if source:find("%-+") then
                source = source:gsub("%-+", "_") -- Match consecutive dashes as one pattern.
            end
            if source:find("%s+") then
                source = source:gsub("%s+", "_") -- Match consecutive spaces as one pattern.
            end
            for key, value in pairs(module) do
                if conflictBehavior == "rename" then
                    -- Renames ALL keys as <source>_<key> to avoid conflicts.
                    target[format("%s_%s", source, key)] = value
                else
                    if target[key] == nil then -- IMPORTANT: Specifically checks if target[key] is nil in case the value is false, in which case we would want to preserve it.
                        target[key] = value
                        originalSource[key] = source -- If target[key] is nil, so is originalSource[key], since they're assigned at the same time.
                    else
                        numConflicts = numConflicts+1
                        local msg
                        if type(key) == "number" then 
                            -- Note that this is entirely pointless, and serves no purpose other than making the log syntax identical to Lua's native key syntax.
                            msg = "An entry with the key [%i] already exists: %s and %s have conflicting entries.\n"
                        else
                            msg = "An entry with the key [\"%s\"] already exists: %s and %s have conflicting entries.\n"
                        end
                        write(format(msg, key, source, originalSource[key]))

                        if conflictBehavior == "replace" then
                            -- Replaces the previous value each time it hits a duplicate key. Resulting value is unreliable due to how pairs() works.
                            target[key] = value

                        elseif conflictBehavior == "merge" then
                            -- Merges conflicting keys into one table. Ensures all values are saved, but is not optimal for some applications.
                            if type(target[key]) == "table" and target[key].__merged then
                            -- If the table was previously merged, simply add the value to it.
                            target[key][source] = value

                            else 
                                -- Create a new merged table using the conflicting key.
                                -- First, save the previous value and overwrite it with a table containing temporary metadata.
                                local oldValue = target[key]
                                target[key] = {__merged = true}

                                -- Then, save the old value using its metadata, followed by the new value.
                                target[key][originalSource[key]] = oldValue
                                target[key][source] = value

                                -- Now, add the merged table to a list of merged tables, and add a helpful function to it via metatable.
                                insert(mergedTables, key) -- This is only temporary; __merged will be removed later.
                                setmetatable(target[key], {
                                    -- Add __call metamethod to inform the user that the function they tried to call is a member of this table:
                                    __call = function(tbl)
                                        -- Build a table of functions contained by this table:
                                        local funcs = {}
                                        for k, v in pairs(tbl) do
                                            table.insert(funcs, k)
                                        end
                                        -- Now build the message and throw an error:
                                        error(string.format("Attempted to call a merged table.\nThis table contains conflicting functions from the following modules: %s\nPlease call the desired function from this table, or create a variable pointing to it.", table.concat(funcs, ", ")), 2)
                                    end
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    if numConflicts > 0 then
        -- If conflicts were encountered, log a warning.
        write(format("Encountered %i conflicts while merging tables. Conflicts were handled using method %s.\n", numConflicts, conflictBehavior))

        if conflictBehavior == "merge" then
            -- Delete temporary metadata from merged tables.
            for _, v in ipairs(mergedTables) do
                target[v].__merged = nil
            end
        end
    end
    return target
end

return export
