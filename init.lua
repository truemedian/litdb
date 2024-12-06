--[[lit-meta
name = "truemedian/litdb"
version = "0.0.1"
dependencies = {
    'luvit/fs',
    'luvit/coro-http',
    'luvit/json',
    'luvit/timer',
    'luvit/coro-websocket',
}
license = "MIT"
homepage = "https://github.com/truemedian/litdb"
private = true
]]

local fs = require('fs')
local http = require('coro-http')
local json = require('json')
local miniz = require('miniz')
local openssl = require('openssl')
local timer = require('timer')
local websocket = require('coro-websocket')

local upstream = 'https://lit.luvit.io'

local function mkdirp(path)
	local parts = {}
	for part in string.gmatch(path, '[^/]+') do
		table.insert(parts, part)
		local success, err, num = fs.mkdirSync(table.concat(parts, '/'))
		assert(success or num == 'EEXIST', err)
	end
end

local function request(path)
	for i = 1, 5 do
		local res, body = http.request('GET', upstream .. path)
		if res.code == 200 then return json.parse(body) end

		timer.sleep(5000)
	end

	error('Failed to fetch ' .. path)
end

mkdirp('litdb-backup.git/refs/tags')

print('requesting author list')

local queries = {}
local authors = request('/packages')
for author in pairs(authors) do
	if not fs.accessSync('litdb-backup.git/refs/tags/' .. author) then
		print('new author', author)
		assert(fs.mkdirSync('litdb-backup.git/refs/tags/' .. author))
	end

	local packages = request('/packages/' .. author)
	for package in pairs(packages) do
		if not fs.accessSync('litdb-backup.git/refs/tags/' .. author .. '/' .. package) then
			print('new package', author, package)
			assert(fs.mkdirSync('litdb-backup.git/refs/tags/' .. author .. '/' .. package))
		end

		local versions = request('/packages/' .. author .. '/' .. package)
		for version in pairs(versions) do
			if not fs.accessSync('litdb-backup.git/refs/tags/' .. author .. '/' .. package .. '/v' .. version) then
				print('new version', author, package, version)

				table.insert(queries, author .. '/' .. package .. ' ' .. version)
			end
		end
	end
end

print('found', #queries, 'new versions')

local res, read, write = assert(websocket.connect({
	host = 'lit.luvit.io',
	port = 443,
	tls = true,
	pathname = '/',
	subprotocol = 'lit',
}))

local function get_root_hash(query)
	print('finding root hash for', query)

	write({
		opcode = 1,
		payload = 'read ' .. query,
	})

	local message = read()
	if not message then error('unexpected EOF') end

	if message.opcode ~= 1 then
		error('unexpected opcode: ' .. message.payload)
	elseif message.payload:byte(1, 1) == 0 then
		error('unexpected error: ' .. message.payload:sub(2))
	else
		local mode, hash = string.match(message.payload, '^(%S+) (.+)$')
		if mode ~= 'reply' then
			error('unexpected reply: ' .. message.payload)
		else
			return hash
		end
	end
end

local function fetch_hash(hash, objects)
	if objects[hash] then return end

	local data = fs.readFileSync('litdb-backup.git/objects/' .. hash:sub(1, 2) .. '/' .. hash:sub(3))
	if data then
		local uncompressed = miniz.inflate(data, 1)
		local hash2 = openssl.digest.digest('sha1', uncompressed, false)

		if hash ~= hash2 then
			data = nil
		else
			objects[hash] = uncompressed
			return uncompressed
		end
	end

	if not data then
		-- print('fetching', hash)

		write({
			opcode = 2,
			payload = string.char(0, 1) .. openssl.hex(hash, false),
		})

		local message = read()
		if message.opcode == 1 or message.payload:byte(1, 1) == 0 then
			if message.payload:sub(2, 13) == 'No such hash' then
				print('fetching', hash, 'no such hash')
				return nil
			else
				error('unexpected error: ' .. message.payload:sub(2))
			end
		end

		data = message.payload
	end

	local uncompressed = miniz.inflate(data, 1)
	local hash2 = openssl.digest.digest('sha1', uncompressed, false)
	if hash ~= hash2 then
		print('hash mismatch: ' .. hash .. ' ' .. hash2)
		return nil
	end

	objects[hash] = uncompressed
	return uncompressed
end

mkdirp('litdb-backup.git/objects')

for i, query in ipairs(queries) do
	local root_hash = get_root_hash(query)

	if root_hash then
		local objects = {}
		local hashes = { root_hash }
		local parents = { [root_hash] = '' }
		local missing = {}
		for _, hash in ipairs(hashes) do
			if not objects[hash] then
				local framed = fetch_hash(hash, objects)

				if framed then
					local kind, size, body = string.match(framed, '^(%S+) (%d+)%z(.*)$')
					if tonumber(size) ~= #body then error('size mismatch: ' .. size .. ' ' .. #body) end

					if kind == 'tree' then
						for mode, name, file_hash in string.gmatch(body, '([0-7]+) ([^%z]+)%z(....................)') do
							file_hash = openssl.hex(file_hash, true)
							if not objects[file_hash] then table.insert(hashes, file_hash) end

							parents[file_hash] = parents[hash] .. '/(' .. mode .. ')' .. name
						end
					elseif kind == 'commit' then
						local tree_hash = assert(string.match(body, '^tree (%x+)\n'), 'missing tree')
						if not objects[tree_hash] then table.insert(hashes, tree_hash) end

						parents[tree_hash] = parents[hash] .. '.tree'

						for parent_hash in string.gmatch(body, '\nparent (%x+)') do
							if not objects[parent_hash] then table.insert(hashes, parent_hash) end

							parents[parent_hash] = parents[hash] .. '.parent'
						end
					elseif kind == 'tag' then
						local object_hash = assert(string.match(body, '^object (%x+)\n'), 'missing object')
						if not objects[object_hash] then table.insert(hashes, object_hash) end

						parents[object_hash] = parents[hash] .. '.object'
					end
				else
					missing[hash] = true
				end
			end
		end

		if next(missing) then
			print('missing', query, root_hash)
			for hash in pairs(missing) do
				print('missing', hash, parents[hash])
			end
		else
			local package, version = string.match(query, '^(%S+) (.+)$')
			for hash, object in pairs(objects) do
				local deflated = assert(miniz.deflate(object, 0x01000 + 4095), 'bad deflate')

				local success, err, num = fs.mkdirSync('litdb-backup.git/objects/' .. hash:sub(1, 2))
				assert(success or num == 'EEXIST', err)
				assert(fs.writeFileSync('litdb-backup.git/objects/' .. hash:sub(1, 2) .. '/' .. hash:sub(3), deflated))
			end

			mkdirp('litdb-backup.git/refs/tags/' .. package)
			assert(fs.writeFileSync('litdb-backup.git/refs/tags/' .. package .. '/v' .. version, root_hash))

			print('saved', query, root_hash)
		end
	else
		print('missing root', query)
	end
end

print('creating tracking branches')

for author in fs.scandirSync('litdb-backup.git/refs/tags') do
	mkdirp('litdb-backup.git/refs/heads/' .. author)

	for package in fs.scandirSync('litdb-backup.git/refs/tags/' .. author) do
		local package_path = 'litdb-backup.git/refs/tags/' .. author .. '/' .. package
		local branch = author .. '/' .. package

		if not fs.accessSync('litdb-backup.git/refs/heads/' .. branch) then print('new branch', branch) end

		local versions = {}
		for version in fs.scandirSync(package_path) do
			local tag_hash = assert(fs.readFileSync(package_path .. '/' .. version))
			local tag_compressed =
				assert(fs.readFileSync('litdb-backup.git/objects/' .. tag_hash:sub(1, 2) .. '/' .. tag_hash:sub(3)))
			local tag_data = assert(miniz.inflate(tag_compressed, 1))
			local tagger, tagtime = string.match(tag_data, '\ntagger ([^<]+%s+<[^>]+>) ([^\n]+)\n')
			local kind = string.match(tag_data, '\ntype (%S+)\n')
			local object = string.match(tag_data, 'object (%S+)\n')

			table.insert(versions, {
				version = version,
				kind = kind,
				object = object,
				tagger = tagger,
				time = tagtime,
			})
		end

		table.sort(versions, function(a, b) return a.time < b.time end)

		local trees = {}
		local commits = {}
		for i, version in ipairs(versions) do
			if version.kind == 'blob' then
				local raw_tree = '100644 file.lua\x00' .. openssl.hex(version.object, false)
				local tree_data = 'tree ' .. tostring(#raw_tree) .. '\x00' .. raw_tree
				local tree_hash = openssl.digest.digest('sha1', tree_data, false)
				table.insert(trees, { hash = tree_hash, data = tree_data })
				version.object = tree_hash
			end

			local data = {}
			table.insert(data, 'tree ' .. version.object)
			if i > 1 then table.insert(data, 'parent ' .. commits[i - 1].hash) end
			table.insert(data, 'author ' .. version.tagger .. ' ' .. version.time)
			table.insert(data, 'committer ' .. version.tagger .. ' ' .. version.time)
			table.insert(data, '')
			table.insert(data, version.version)

			local raw_commit = table.concat(data, '\n')
			local commit_data = 'commit ' .. tostring(#raw_commit) .. '\x00' .. raw_commit
			local commit_hash = openssl.digest.digest('sha1', commit_data, false)
			table.insert(commits, {
				hash = commit_hash,
				data = commit_data,
			})
		end

		for _, data in ipairs(trees) do
			local deflated = assert(miniz.deflate(data.data, 0x01000 + 4095), 'bad deflate')
			local hash = data.hash

			local success, err, num = fs.mkdirSync('litdb-backup.git/objects/' .. hash:sub(1, 2))
			assert(success or num == 'EEXIST', err)
			assert(fs.writeFileSync('litdb-backup.git/objects/' .. hash:sub(1, 2) .. '/' .. hash:sub(3), deflated))
		end

		for _, data in ipairs(commits) do
			local deflated = assert(miniz.deflate(data.data, 0x01000 + 4095), 'bad deflate')
			local hash = data.hash

			local success, err, num = fs.mkdirSync('litdb-backup.git/objects/' .. hash:sub(1, 2))
			assert(success or num == 'EEXIST', err)
			assert(fs.writeFileSync('litdb-backup.git/objects/' .. hash:sub(1, 2) .. '/' .. hash:sub(3), deflated))
		end

		if #commits > 0 then
			assert(fs.writeFileSync('litdb-backup.git/refs/heads/' .. author .. '/' .. package, commits[#commits].hash))
		end
	end
end

res.socket:close()
