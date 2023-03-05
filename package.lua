--[[
version: 1.0.0
	Newest version reworks the entire module.
	Removed use of options 'cause code or partial code losted (rework it or find it out).
version: 1.3.1
	Actual advantage
version: 2.0.0bw
	Include new features.
	Removed the use of bizarre props, now it is in the init file.
	Added usage of `prop` that is a "class" helper
	Store has minimal changed, the method remain the same but some minor changes.

	working on:
		→ point: but I don't want more that ridiculous name.
		the Core of the library is in there.
		what could be a good name?
		and how can i better anage the stores?
	
	on the way:
		→ change the `path`s management to a exclusive file
		→ possible create of an individual `class` module
		→ the `prop` is prabably deleted, because it's an experiment

		change the ~ another Core that is `content`, i'll working hard on it cause is my good.
]]

return {
	name = 'Corotyest/bestore',
	version = '1.6.0',
	dependencies = {
		'Corotyest/content',
		'Corotyest/format'
	}
}