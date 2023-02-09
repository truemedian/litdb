require 'lua-extensions'()

local spawn = require 'coro-spawn'
local parse = require 'url'.parse

local wrap = coroutine.wrap
local format = string.format

if not spawn ('youtube-dl', { }) then
	error 'YOUTUBE-DL WAS NOT FOUND'
end

--- This process need to be called in a coroutine or wraped in one, the `option` is optional, and you can pass
--- `url` as "nil", but the callback is explicit needed.
---@param option? string
---@param url string
---@param callback function
---@return any
local function _spawn(option, url, callback, ...)
	if type(url) ~= 'string' then
		return nil, 'Invalid url.'
	elseif type(callback) ~= 'function' then
		return nil, 'Invalid callback.'
	end

	local base = { option or '-g' }

	if ... then
		local n, vn = #base, select('#', ...)
		for i = 1, vn do base[i+n] = select(i, ...) end
		base[#base + 1] = url
	else
		base = { option or '-g', url }
	end

	local data = spawn('youtube-dl', {
		args = { unpack(base) },
		stdio = { nil, true, 2 }
	})

	for chunk in data.stdout.read do
		local real = chunk:split('\n')

		if #real ~= 0 then
			for _, value in pairs(real) do
				local mime = parse(value, true).query.mime
				local audio =
					mime and mime:find('audio') == 1
				if audio then callback(value) elseif not mime then callback(value) end
			end
		else
			callback(chunk)
		end
	end
end

local options, indexes = {
	'-e', -- video title
	'--get-thumbnail', -- video thumbnail
	'--get-duration', -- video duration
}, {
	'title',
	'thumbnail',
	'duration'
}

--- Get the video information in base `video` it may be a search or an url, use the callback to obtain the
--- response (as it first value).
---@param video string
---@param callback function
local function videoInfoCard(video, callback)
	if type(video) ~= 'string' then
		return nil, 'Invalid video.'
	elseif type(callback) ~= 'function' then
		return nil, 'Invalid callback.'
	end

	local base = {}
	local protocol = parse(video).protocol == true

	if not protocol then
		base[#base + 1] = format('%s:"%s"', 'ytsearch', video); base[#base + 1] = '-g'
	end

	local n = #base
	for i, option in pairs(options) do
		if #base == 2 then n = n + 1 end
		base[n + i] = option
	end

	if protocol then base[#base + 1] = video end

	local response, index = {}, 1
	base[3] = function(value)
		local i = not protocol and value:find('audio') and 'url'
		response[i or indexes[index]] = value
		if i then index = index - 1 end
		if not protocol and index == #indexes or protocol and index == #indexes then
			callback(response)
		end
		index = index + 1
	end

	wrap(_spawn)(unpack(base))
end

return {
	parse = parse,
	_spawn = _spawn,
	videoInfoCard = videoInfoCard,
}