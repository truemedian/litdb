
-- direct/loader
-- @code-nuage

local fs = require("coro-fs")

local loader = {}

loader.read = function(path)
    local data = fs.readFile(path)
    return data
end

return loader
