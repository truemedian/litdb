---Some lunalink additional config option
---@class LunalinkConfig
---<!tag:properties>
---@field additionalDriver table Additional custom driver for rainlink (no need 'new' keyword when add). Example: `additionalDriver: Lavalink4`
---@field retryTimeout number Timeout before trying to reconnect (ms)
---@field retryCount number Number of times to try and reconnect to Lavalink before giving up
---@field voiceConnectionTimeout number  The retry timeout for voice manager when dealing connection to discord voice server (ms)
---@field defaultSearchEngine string The default search engine like default search from youtube, spotify,...
---@field defaultVolume number The default volume when create a player
---@field searchFallback SearchFallback Search track from youtube when track resolve failed
---@field resume number Whether to resume a connection on disconnect to Lavalink (Server Side) (Note: DOES NOT RESUME WHEN THE LAVALINK SERVER DIES)
---@field resumeTimeout number When the seasion is deleted from Lavalink. Use second (Server Side) (Note: DOES NOT RESUME WHEN THE LAVALINK SERVER DIES)
---@field userAgent string User Agent to use when making requests to Lavalink
---@field nodeResolver function Node Resolver to use if you want to customize it `function (nodes) end`
---@field structures Structures Number of times to try and reconnect to Lavalink before giving up


---Lunalink config interface
---@class LunalinkOptions
---<!tag:properties>
---@field nodes LunalinkNodeOptions The lavalink server credentials array
---@field library AbstractLibrary The discord library for using voice manager, example: discordjs, erisjs
---@field plugins LunalinkPlugin The rainlink plugins array. Check Plugin
---@field config LunalinkConfig Lunalink config options


---Search fallback config
---@class SearchFallback
---<!tag:properties>
---@field enable boolean Whenever enable this search fallback or not
---@field engine string Choose a fallback search engine, recommended soundcloud and youtube


---The structures options interface for custom class/structures
---@class Structures
---<!tag:properties>
---@field rest class A custom structure that extends the Rest class `class('Extended', require('lunalink').Rest)`
---@field player class A custom structure that extends the Player class `class('Extended', require('lunalink').Player)`
---@field queue class A custom structure that extends the Queue class `class('Extended', require('lunalink').Queue)`
---@field filter class A custom structure that extends the Filter class `class('Extended', require('lunalink').Filter)`


---Node options for Lunalink
---@class LunalinkNodeOptions
---<!tag:properties>
---@field name string Name for get the lavalink server info in rainlink
---@field host string The ip address or domain of lavalink server
---@field port string The port that lavalink server exposed
---@field auth string The password of lavalink server
---@field secure boolean Whenever lavalink use ssl or not
---@field driver string The driver class for handling lavalink response
---@field region string The region of the node