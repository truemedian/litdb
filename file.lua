--[[
    Multi-file command loader, designed to load all modules in a directory and return them as one table.

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
-- Lit metadata:
exports.name = "Samur3i/direct-loader"
exports.version = "1.2.1"
exports.license = "MIT"
exports.homepage = "https://github.com/Samur3i/direct-loader"
exports.dependencies = {
    "luvit/fs"
}

local module = {}
local fs = require("fs")

local function printf(str, ...)
    return io.write(str:format(...))
end

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

function module.load(path, conflictBehavior)
    -- Function to load all scripts from a given directory, then return the results from them as one table.
    -- Returns the new table on success, nil and an error on failure.
    if type(path) ~= "string" then
        return nil, "Unexpected type to argument #1 (string expected, got "..type(path)..")"
    elseif not isDir(path) then
        return nil, "No such directory: "..path
    end

    conflictBehavior = conflictBehavior or "merge"
    if conflictBehavior ~= "merge" and conflictBehavior ~= "replace" and conflictBehavior ~= "ignore" and conflictBehavior ~= "rename" then
        return nil, "Unexpected value \""..conflictBehavior.."\" to argument #2"
    end
    --[[ 
        Defining conflictBehavior is optional, and defaults to "merge"
        When set to "merge", compile() will merge conflicted entries into a table named <key> containing the duplicate keys' values, stored using integer keys.
        The other optional modes are "ignore" and "replace". 
        Using "ignore" will ignore any duplicate keys and keep only the first value.
        Using "replace" will overwrite the previous value with the new value.

        All methods are unreliable due to how pairs works, meaning that the same value or order can not be guaranteed across multiple calls.
        This behavior is why merge is the default/safest behavior, though it is recommended to have no duplicate keys at all.

        Regardless of the behavior chosen, compile() will log all conflicts.
    --]]

    local insert = table.insert -- Localize table.insert to improve performance on large tables.
    local returns = {} -- Table to store the results from each require in.
    local parent = {} -- Create an empty table to store metadata in.

    printf("Loading modules from directory: %s\n", path)
    for fname, ftype in fs.scandirSync(path) do
        if ftype == "file" and fname:find("%.lua") then
            -- Build the require path by stripping the extension from the filename using string.match()
            -- Then attempt to require the module using that path in a protected call.
            local name = fname:match("(.+)%.lua")
            local scriptPath = path.."/"..name
            local success, result = pcall(require, scriptPath)
            if not success then
                -- If the require failed, log the error and move on.
                io.write(result.."\n")
            else
                returns[name] = result
                printf("Loaded %s\n", fname)
            end
        end
    end
    if next(returns) == nil then
        -- Nothing was returned. Return nil since continuing would be pointless.
        return nil, "No modules loaded from directory: "..path
    end

    -- Begin building the new table:
    local target = {} -- Create an empty table to build into.
    local numConflicts = 0 -- Store the number of conflicts encountered while merging the tables.
    local mergedTables = {} -- Store an index of merged tables so that metadata can be removed once the new table is complete.

    io.write("Building new table...\n")
    for metakey, module in pairs(returns) do
        -- Iterates through the provided table, looking for nested tables.
        -- Upon finding a nested table, iterates through it, adding everything in that table to the new, combined table.
        if type(module) == "table" then
            -- Check if metakey has a dash or space, and replace it with an underscore.
            if metakey:find("%-") then
                metakey = metakey:gsub("%-+", "_") -- Match consecutive dashes as one pattern.
            end
            if metakey:find("%s+") then
                metakey = metakey:gsub("%s+", "_") -- Match consecutive spaces as one pattern.
            end

            for key, value in pairs(module) do
                if conflictBehavior == "rename" then
                    -- Renames ALL keys as <metakey>_<key> to avoid conflicts.
                    target[metakey.."_"..key] = value
                else
                    if target[key] == nil then -- IMPORTANT: Specifically checks if target[key] is nil in case the value is false, in which case we would want to preserve it.
                        target[key] = value
                        parent[key] = metakey -- If target[key] is nil, so is parent[key], since they're assigned at the same time.
                    else
                        numConflicts = numConflicts+1
                        local msg
                        if type(key) == "number" then 
                            -- Note that this is entirely pointless, and serves no purpose other than making the log syntax identical to Lua's native key syntax.
                            msg = "An entry with the key ["..key.."] already exists. %s\n"
                        else
                            msg = "An entry with the key [\""..key.."\"] already exists. %s\n"
                        end

                        if conflictBehavior == "ignore" then
                            -- Ignores duplicates, preserving only the first value assigned. Resulting value is unreliable due to how pairs() works.
                            printf(msg, "Ignoring duplicate key.")

                        elseif conflictBehavior == "replace" then
                            -- Replaces the previous value each time it hits a duplicate key. Resulting value is unreliable due to how pairs() works.
                            target[key] = value
                            printf(msg, "Replacing previous value.")

                        elseif conflictBehavior == "merge" then
                            -- Merges conflicting keys into one table. Ensures all values are saved, but is not optimal for some applications.
                            if type(target[key]) == "table" and target[key].__merged then
                            -- If the table was previously merged, simply add the value to it.
                            target[key][metaKey] = value
                            printf(msg, "Added new value to previously merged table.")

                            else 
                                -- Create a new merged table using the conflicting key.
                                -- First, save the previous value and overwrite it with a table containing temporary metadata.
                                local oldValue = target[key]
                                target[key] = {__merged = true}
                                -- Then, save the old value using its metadata, followed by the new value.
                                target[key][parent[key]] = oldValue
                                target[key][metakey] = value
                                insert(mergedTables, key) -- Keep track of merged tables so that __merged can be removed later.
                                printf(msg, "Merged duplicate keys' values into new table.")
                            end
                        end
                    end
                end
            end
        end
    end

    if numConflicts > 0 then
        -- If conflicts were encountered, log a warning.
        printf("Encountered %i conflicts while merging tables. Conflicts were handled using method %s.\n", numConflicts, conflictBehavior)

        if conflictBehavior == "merge" then
            -- Delete temporary metadata from merged tables.
            for _, v in ipairs(mergedTables) do
                target[v].__merged = nil
            end
        end
    end
    return target
end

return module
