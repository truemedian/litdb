--[[lit-meta
	name = 'TohruMKDM/unzip'
	version = '1.0.1'
	homepage = 'https://github.com/TohruMKDM/lua-unzip'
	description = 'zlib-compressed file depacking library in Lua.'
	tags = {'decompression', 'deflation', 'zlib'}
	license = 'MIT'
	author = {name = 'Tohru~ (トール)', email = 'admin@ikaros.pw'}
    contributors = {'zerkman', 'samhocevar'}
]]

local lshift, rshift, band do
    local bit = bit32 or bit
    lshift, rshift, band = bit.lshift, bit.rshift, bit.band
end
local concat, unpack = table.concat, unpack or table.unpack
local sub, find, byte, char = string.sub, string.find, string.byte, string.char
local min = math.min
local order = {17, 18, 19, 1, 9, 8, 10, 7, 11, 6, 12, 5, 13, 4, 14, 3, 15, 2, 16}
local bitsTable = {2, 3, 7}
local counts = {144, 112, 24, 8}
local depthsTable = {8, 9, 7, 8}
local distMap = {5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5}

local function flushBits(stream, number)
    stream.count = stream.count - number
    stream.bits = rshift(stream.bits, number)
end

local function peekBits(stream, number)
    while stream.count < number do
        stream.bits = stream.bits + lshift(byte(stream.buffer, stream.position), stream.count)
        stream.position = stream.position + 1
        stream.count = stream.count + 8
    end
    return band(stream.bits, lshift(1, number) - 1)
end

local function getBits(stream,  number)
    local result = peekBits(stream, number)
    stream.count = stream.count - number
    stream.bits = rshift(stream.bits, number)
    return result
end

local function getElement(stream, hufftable, number)
    local element = hufftable[peekBits(stream, number)]
    local length = band(element, 15)
    local result = rshift(element, 4)
    stream.count = stream.count - length
    stream.bits = rshift(stream.bits, length)
    return result
end

local function huffman(depths)
    local size = #depths
    local bits, code = 1, 0
    local blocks, codes, hufftable = {}, {}, {}
    blocks[0] = 0
    for i = 1, size do
        local depth = depths[i]
        if depth > bits then
            bits = depth
        end
        blocks[depth] = (blocks[depth] or 0) + 1
    end
    for i = 1, bits do
        code = (code + (blocks[i - 1] or 0)) * 2
        codes[i] = code
    end
    for i = 1, size do
        local depth = depths[i]
        if depth > 0 then
            local e = (i - 1) * 16 + depth
            local y = 0
            code = codes[depth]
            for x = 1, depth do
                y = y + lshift(band(1, rshift(code, x - 1)), depth - x)
            end
            for x = 0, 2 ^ bits - 1, 2 ^ depth do
                hufftable[x + y] = e
            end
            codes[depth] = codes[depth] + 1
        end
    end
    return hufftable, bits
end

local function loop(output, stream, litTable, litCount, distTable, distCount)
    local lit
    repeat
        lit = getElement(stream, litTable, litCount)
        if lit < 256 then
            output[#output + 1] = lit
        elseif lit > 256 then
            local bits, dist, size = 0, 1, 3
            if lit < 265 then
                size = size + lit - 257
            elseif lit < 285 then
                bits = rshift(lit - 261, 2)
                size = size + lshift(band(lit - 261, 3) + 4, bits)
            else
                size = 258
            end
            if bits > 0 then
                size = size + getBits(stream, bits)
            end
            local element = getElement(stream, distTable, distCount)
            if element < 4 then
                dist = dist + element
            else
                bits = rshift(element - 2, 1)
                dist = dist + lshift(band(element, 1) + 2, bits) + getBits(stream, bits)
            end
            local position = #output - dist + 1
            while size > 0 do
                output[#output + 1] = output[position]
                position = position + 1
                size = size - 1
            end
        end
    until lit == 256
end

local function uncompressed(output, stream)
    flushBits(stream, band(stream.count, 7))
    local length = getBits(stream, 16); getBits(stream, 16)
    local buffer = stream.buffer
    local position = stream.position
    for i = position, position + length - 1 do
        output[#output + 1] = byte(buffer, i, i)
    end
    stream.position = position + length
end

local function static(output, stream)
    local litDepths = {}
    for i = 1, 4 do
        local depth = depthsTable[i]
        for x = 1, counts[i] do
            litDepths[#litDepths + 1] = depth
        end
    end
    local litTable, litCount = huffman(litDepths)
    local distTable, distCount = huffman(distMap)
    loop(output, stream, litTable, litCount, distTable, distCount)
end

local function dynamic(output, stream)
    local lit, dist, length = 257 + getBits(stream, 5), 1 + getBits(stream, 5), 4 + getBits(stream, 4)
    local depths = {}
    for i = 1, length do
        depths[order[i]] = getBits(stream, 3)
    end
    for i = length + 1, 19 do
        depths[order[i]] = 0
    end
    local hufftable, bits = huffman(depths)
    local i = 1
    while i <= lit + dist do
        local element = getElement(stream, hufftable, bits)
        if element < 16 then
            depths[i] = element
            i = i + 1
        elseif element < 19 then
            local a, b = 0, 3 + getBits(stream, bitsTable[element - 15])
            if element == 16 then
                a = depths[i - 1]
            elseif element == 18 then
                b = b + 8
            end
            for _ = 1, b do
                depths[i] = a
                i = i + 1
            end
        end
    end
    local litDepths, distDepths = {}, {}
    for x = 1, lit do
        litDepths[x] = depths[x]
    end
    for x = lit + 1, #depths do
        distDepths[#distDepths + 1] = depths[x]
    end
    local litTable, litCount = huffman(litDepths)
    local distTable, distCount = huffman(distDepths)
    loop(output, stream, litTable, litCount, distTable, distCount)
end

local function newStream(data)
    local start = find(data, 'PK\5\6')
    if start then
        data = sub(data, 1, start + 19)..'\0\0'
    end
    return {buffer = data}
end

local function inflate(stream, offset)
    local output, buffer = {}, {}
    local last, typ
    stream.position = offset
    stream.bits = 0
    stream.count = 0
    repeat
        last, typ = getBits(stream, 1), getBits(stream, 2)
        typ = typ == 0 and uncompressed(output, stream) or typ == 1 and static(output, stream) or typ == 2 and dynamic(output, stream)
    until last == 1
    local size = #output
    for i = 1, size, 1000 do
        buffer[#buffer + 1] = char(unpack(output, i, min(i - 1 + 1000, size)))
    end
    return concat(buffer)
end

local function int2le(data, position)
    local a, b = byte(data, position, position + 1)
    return b * 256 + a
end

local function int4le(data, position)
    local a, b, c, d = byte(data, position, position + 3)
    return ((d * 256 + c) * 256 + b) * 256 + a
end

local function iterate(data)
    local i = int4le(data, (#data - 21) + 16) + 1
    return function()
        if int4le(data, i) ~= 33639248 then
            return
        end
        local deflated = int2le(data, i + 10) ~= 0
        local length = int2le(data, i + 28)
        local name = sub(data, i + 46, i + 45 + length)
        local offset = int4le(data, i + 42) + 1
        i = i + 46 + length + int2le(data, i + 30) + int2le(data, i + 32)
        return name, offset + 30 + length + int2le(data, offset + 28), int4le(data, offset + 18), deflated
    end
end

local function getFiles(stream, unzip)
    local data = stream.buffer
    if unzip then
        local iterator = iterate(data)
        return function()
            local name, offset, size, deflated = iterator()
            if not name then
                return
            end
            if deflated then
                return name, inflate(stream, offset)
            end
            return name, sub(data, offset, offset + size - 1)
        end
    end
    return iterate(data)
end

return {
    newStream = newStream,
    inflate = inflate,
    getFiles = getFiles
}