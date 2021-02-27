--- General Config
name = "lit-glob"

--- Format
format = "markdown"

--- Language
language = {single = "--", multi = {"--[[", "]]--"}}

--- Files
-- Input
input = {"*.lua"}

-- Transform
transform = function(path) return "index.md" end

-- Output folder
output = "docs"

-- Ignore
ignore = {"Fir.lua", "package.lua"}
