--[[lit-meta
	name = "RiskoZoSlovenska/vips-utils"
	version = "0.1.0"
	homepage = "https://github.com/RiskoZoSlovenska/lua-vips-utils"
	description = "A handful of utilities for working with VIPS"
	tags = {"image-processing", "images", "vips", "libvips", "utilities"}
	license = "MIT"
	author = "RiskoZoSlovenska"
]]

local Image = require("vips").Image



local function multiplyTable(tbl, mult)
	if mult == 1 then return tbl end

	for i = 1, #tbl do
		tbl[i] = tbl[i] * mult
	end

	return tbl
end



-- https://github.com/libvips/libvips/issues/1201#issuecomment-450854394
local function equal(image1, image2)
	if image1 == image2 then return true end

	return image1:equal(image2):min() == 255
end



local function normalize(image)
	image = image:colourspace("srgb")

	if image:bands() > 3 then -- if image:hasalpha() then
		local bands = image:bandsplit()
		local alpha = table.remove(bands)

		return Image.bandjoin(bands), alpha
	else
		return image, Image.new_from_image(image, 255)
	end
end

local function normalizedFromFile(filename, ...)
	return normalize(Image.new_from_file(filename, ...))
end

local function normalizedFromBuffer(buf, options, ...)
	return normalize(Image.new_from_buffer(buf, options, ...))
end



local function simplify(image, coefficient)
	return image:resize(1 / coefficient):bandmean()
end



local function search(image, target, simplification, fullCor, numToFind)
	if simplification then
		image = simplify(image, simplification)
	else
		simplification = 1
	end

	local cor  = fullCor and Image.spcor or Image.fastcor
	local comp = fullCor and Image.max   or Image.min

	local _, x, y, _, xs, ys = comp(cor(image, target), {size = numToFind or nil})

	if numToFind and numToFind > 1 then
		return multiplyTable(xs, simplification),
		       multiplyTable(ys, simplification)
	else
		return x * simplification,
		       y * simplification
	end
end



-- https://en.wikipedia.org/wiki/SRGB#Transformation
local function removeSrgbGamma(image)
	return image:more(0.04045):ifthenelse(
		((image + 0.055) / 1.055)^2.4,
		image / 12.92
	)
end

local function addSrgbGamma(image)
	return image:more(0.0031308):ifthenelse(
		1.055 * image^(1 / 2.4) - 0.055,
		12.92 * image
	)
end



local function writeAndRead(image, formatStr)
	local buf = image:write_to_buffer(formatStr or ".png")
	return Image.new_from_buffer(buf)
end



local function rollToFrames(roll, frameHeight)
	local frames = {
		images = {},
		durations = roll:get("delay"),
		n = nil,
	}
	if not type(frames.durations) == "table" then
		error("bad delay data in roll image", 2)
	end

	frameHeight = frameHeight or tonumber(roll:get("page-height"))
	if not frameHeight then
		error("bad page-height data in roll image", 2)
	end

	local width = roll:width()
	for i = 0, (roll:height() / frameHeight) - 1 do
		table.insert(frames.images, roll:extract_area(0, i * frameHeight, width, frameHeight))
	end
	frames.n = #frames.images

	return frames
end

local function removeDuplicateFrames(frames)
	local prev, prevDuration = nil, 0

	local newFrames = {
		images = {},
		durations = {},
		n = nil,
	}

	for i = 1, frames.n do
		local image, duration = frames.images[i], frames.durations[i]

		if prev and equal(prev, image) then
			prevDuration = prevDuration + duration
		else
			if prev then -- Don't insert the first nil prev
				table.insert(newFrames.images, prev)
				table.insert(newFrames.durations, prevDuration)
			end

			prev = image
			prevDuration = duration
		end
	end

	table.insert(newFrames.images, prev)
	table.insert(newFrames.durations, prevDuration)

	newFrames.n = #newFrames.images

	return newFrames
end

local function framesToRoll(frames, removeDuplicates)
	if removeDuplicates then
		frames = removeDuplicateFrames(frames)
	end

	local image = Image.arrayjoin(frames.images, {across = 1})

	image:set("page-height", frames.images[1]:height())
	image:set("delay", frames.durations)

	return image
end



local function stringify(image, name, padding)
	local buf = {name or "image"}
	local format = string.format("%%-%ds ", (padding or 20) - 1)

	for y = 0, image:height() - 1 do
		for x = 0, image:width() - 1 do
			local values = {image(x, y)}

			for i = 1, #values do
				values[i] = string.format(format, values[i])
			end

			table.insert(buf, "\t" .. table.concat(values))
		end
	end

	return table.concat(buf, "\n")
end

local function printImage(image, ...)
	print(stringify(image, ...))
end



return {
	equal = equal,

	normalize = normalize,
	normalizedFromFile = normalizedFromFile,
	normalizedFromBuffer = normalizedFromBuffer,

	writeAndRead = writeAndRead,

	simplify = simplify,
	search = search,

	removeSrgbGamma = removeSrgbGamma,
	addSrgbGamma = addSrgbGamma,

	rollToFrames = rollToFrames,
	framesToRoll = framesToRoll,
	removeDuplicateFrames = removeDuplicateFrames,

	stringify = stringify,
	print = printImage,
}