local fs = require("fs")

local function mkdirp(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
        table.insert(parts, part)
        local success, err, num = fs.mkdirSync(table.concat(parts, "/"))
        assert(success or num == "EEXIST", err)
    end
end

local packs = {}

for pack in fs.scandirSync(".git/objects/pack") do
	if pack:match("%.pack$") then
		fs.renameSync(".git/objects/pack/" .. pack, "./" .. pack)
        table.insert(packs, pack)
    else
        fs.unlinkSync(".git/objects/pack/" .. pack)
	end

end

for _, pack in ipairs(packs) do
	local contents = fs.readFileSync(pack)
	print("unpacking", pack)

	local proc = io.popen("git unpack-objects < " .. pack, "w")
	proc:close()
end

for _, pack in ipairs(packs) do
    fs.unlinkSync(pack)
end

local packed_refs = io.popen("git show-ref --tags --heads", "r")
for line in packed_refs:lines() do
    local hash, ref = line:match("^(%w+) (.+)$")
    if hash and ref then
        mkdirp(".git/" .. ref:match("(.+)/[^/]+$"))
        fs.writeFileSync(".git/" .. ref, hash)
    end
end