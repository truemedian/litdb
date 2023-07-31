local enum = require("api/enum/init")

--[[@
	@name gender
	@desc The profile gender ID.
	@type int
]]
enum.gender = {
	none   = 0,
	female = 1,
	male   = 2
}

--[[@
	@name role
	@desc The ID for staff role identifiers.
	@type int
]]
enum.role = enum {
	normal        = 00,
	moderator     = 05,
	administrator = 10,
	mapcrew       = 11,
	funcorp       = 13
}

enum.updatePlayer = enum {
	general         = 1,
	shamanColor     = 2,
	score           = 3,
	movement        = 4,
	ducking         = 5
}

enum.outfitCategory = enum {
	head          = 1,
	eyes          = 2,
	ears          = 3,
	mouth         = 4,
	neck          = 5,
	hairStyle     = 6,
	tail          = 7,
	contactLenses = 8,
	hands         = 9
}