--[[lit-meta
	name = "Corotyest/vipitils"
	version = "1.0.0"
	homepage = "https://github.com/Corotyest/vipitils"
	description = "A handful of utilities for working with VIPS"
	tags = {"image-processing", "images", "vips", "libvips", "utilities"}
	license = "MIT"
	author = "Corotyest"
]]

-- Credits to: @RiskoZoSlovenska

local Image = require("vips").Image

local format = string.format
local argErr = 'bad argument #%d for %s (type %s expected, got %s)'


--- Multiply the contents of the `tbl` by the number `mult`. Returns the argument `tbl`.
---@param tbl table
---@param mult number
---@return table
local function multiplyTable(tbl, mult)
	if mult == 1 then return tbl end

	for i = 1, #tbl do
		tbl[i] = tbl[i] * mult
	end

	return tbl
end

-- https://github.com/libvips/libvips/issues/1201#issuecomment-450854394

--- Compare `image1` with the `image2` as it are equals, those must be VipsImages.
---@param image1 VipsImage
---@param image2 VipsImage
---@return boolean
local function equal(image1, image2)
	return image1 == image2 and true or image1:equal(image2):min() == 255
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

--- "Simplify"s a `image` that is a VipsImage in base to the `coefficient`.
---@param image VipsImage
---@param coefficient number
---@return VipsImage
local function simplify(image, coefficient)
	local type2 = type(coefficient)
	if type2 ~= 'number' then
		return nil, format(argErr, 2, 'simplify', 'number', type2)
	end
	return image:resize(1 / coefficient):bandmean()
end

--- Searchs through `target` the `image` passed as the first argument, `simplification` makes the TWO images "fit" better.
--- The `fullCor` argument "iterate" the image and throws better coordinates, but it cost more time.
---@param image VipsImage
---@param target VipsImage
---@param simplification number?
---@param fullCor any?
---@param numToFind number?
---@return number, number | table
local function search(image, target, simplification, fullCor, numToFind)
	local type1, type2, type3, type4 = type(image), type(target), type(simplification), type(numToFind)
	if not Image.is_Image(image) then
		return nil, format(argErr, 1, 'search', 'VipsImage', type1)
	elseif not Image.is_Image(target) then
		return nil, format(argErr, 2, 'search', 'VipsImage', type2)
	elseif numToFind and type4 ~= 'number' then
		return nil, format(argErr, 4, 'search', 'number', type4)
	end

	if type3 == 'number' then
		image = simplify(image, simplification); target = simplify(target, simplification)
	else
		simplification = 1
	end

	local cor  = fullCor and Image.spcor or Image.fastcor
	local comp = fullCor and Image.max   or Image.min

	local value = cor(image, target)
	local time, x, y, _, xs, ys = comp(value, { size = numToFind or nil })

	if numToFind and numToFind > 1 then
		return multiplyTable(xs, simplification),
		       multiplyTable(ys, simplification)
	else
		return x * simplification,
		       y * simplification
	end

	return nil, 'Not matched'
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

-- First write the passed `image` in the buffer withe the passed `format` and then returns a `VipsOperation`.
---@param image VipsImage
---@param format string?
---@return VipsOperation
local function writeAndRead(image, format)
	local buf = image:write_to_buffer(format or ".png")
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

--- Make the passed `image` that is a `VipsImage` a normal Lua string, provide a `name` to the be `image` "name" and a `padding`.
---@param image VipsImage
---@param name string?
---@param padding number?
---@return string
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

--- Print the `image` a VipsImage on string format.
---@param image VipsImage
---@vararg any
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