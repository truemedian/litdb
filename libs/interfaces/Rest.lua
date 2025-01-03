---Interface for :updatePlayer() function
---@class UpdatePlayerInfo
---<!tag:properties>
---@field guildId string Target guild identifier
---@field playerOptions '[UpdatePlayer](https://lavalink.dev/api/rest.html#update-player)' Player options to update
---@field noReplace boolean Whether to replace the current track with the new track


---Interface for raw audio server track
---@class RawTrack
---<!tag:properties>
---@field encoded string Encoded track string, contanins all required infomation
---@field info RawTrackInfo Main infomation of track
---@field pluginInfo unknown Additional infomation for plugin


---Interface for raw audio server track information
---@class RawTrackInfo
---<!tag:properties>
---@field identifier string Identifier string from lavalink
---@field isSeekable boolean Whenever track is seekable or not
---@field author string Track's author
---@field length number Track's duration
---@field isStream boolean Whenever track is stream able or not
---@field position number Track's position
---@field title string Track's title
---@field uri 'string/nil' Track's URL
---@field artworkUrl 'string/nil' Track's artwork URL
---@field isrc 'string/nil' Track's isrc
---@field sourceName string Track's source name