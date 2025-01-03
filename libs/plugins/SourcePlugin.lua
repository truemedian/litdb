local class = require('class')

local SourcePlugin = class('SourcePlugin')

---The interface class for track resolver plugin, extend it to use
---@class SourcePlugin: Plugin
---@field isLunalinkPlugin boolean Is a lunalink plugin or not

function SourcePlugin:__init() end

---sourceName function for source plugin register search engine.
---This will make plugin avalible to search when set the source to default source
---@return nil
function SourcePlugin:sourceName()
  error('Source plugin must implement sourceName() and return as string')
end

---sourceIdentify function for source plugin register search engine.
---This will make plugin avalible to search when set the source to default source
---@return nil
function SourcePlugin:sourceIdentify()
  error('Source plugin must implement sourceIdentify() and return as string')
end

---directSearchChecker function for checking if query have direct search param.
---@param query string
---@return nil
function SourcePlugin:directSearchChecker(query)
	local directSearchPattern = 'directSearch=(.+)'
	local isDirectSearch = string.match(query, directSearchPattern)
  return type(isDirectSearch) == 'nil'
end

---searchDirect function for source plugin search directly without fallback.
---This will avoid overlaps in search function
---@param query string
---@param options SearchOptions
---@return SearchResult
function SourcePlugin:searchDirect(query, options)
  error('Plugin must implement name() and return a plguin name string')
end

return SourcePlugin