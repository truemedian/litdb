local byteArray = require("bArray")
local bitwise = require("bitwise")

-- Optimization --
local bit_band = bit.band
local bit_bxor = bit.bxor
local bitwise_band = bitwise.band
local bitwise_bxor = bitwise.bxor
local bitwise_lshift = bitwise.lshift
local bitwise_rshift = bitwise.rshift
local math_floor = math.floor
local string_char = string.char
local string_sub = string.sub
local table_concat = table.concat
local table_setNewClass = table.setNewClass
local table_writeBytes = table.writeBytes
------------------

local encode = table_setNewClass()

--[[@
	@name new
	@desc Creates a new instance of Encode. Alias: `encode()`.
	@param hasSpecialRole?<boolean> Whether the bot has the game's special role bot or not.
	@returns encode The new Encode object.
	@struct {
		hasSpecialRole = false, -- Whether the bot has the game's special role bot or not.
		identificationKeys = { }, -- The identification keys of the SWF/endpoint.
		messageKeys = { } -- The message keys of the SWF/endpoint.
	}
]]
encode.new = function(self, hasSpecialRole)
	return setmetatable({
		hasSpecialRole = hasSpecialRole,
		identificationKeys = nil,
		messageKeys = nil
	}, self)
end

do
	local openssl = require("openssl") -- built-in
	local sha256 = openssl.digest.get("sha256")

	-- Aux function to getPasswordHash
	local cryptToSha256 = function(str)
		local hash = openssl.digest.new(sha256)
		hash:update(str)
		return hash:final()
	end

	local saltBytes = table_writeBytes({
		0xF7, 0x1A, 0xA6, 0xDE,
		0x8F, 0x17, 0x76, 0xA8,
		0x03, 0x9D, 0x32, 0xB8,
		0xA1, 0x56, 0xB2, 0xA9,
		0x3E, 0xDD, 0x43, 0x9D,
		0xC5, 0xDD, 0xCE, 0x56,
		0xD3, 0xB7, 0xA4, 0x05,
		0x4A, 0x0D, 0x08, 0xB0
	})

	local base64_encode = require("base64").encode -- built-in
	--[[@
		@name getPasswordHash
		@desc Encrypts the account's password.
		@param password<string> The account's password.
		@returns string The encrypted password.
	]]
	encode.getPasswordHash = function(password)
		local hash = cryptToSha256(password)
		hash = cryptToSha256(hash .. saltBytes)
		local len = #hash

		local out, counter = { }, 0
		for i = 1, len, 2 do
			counter = counter + 1
			out[counter] = string_char(tonumber(string_sub(hash, i, (i + 1)), 16))
		end

		return base64_encode(table_concat(out))
	end
end

local xxtea
do
	local DELTA, LIM = 0x9E3779B9, 0xFFFFFFFF

	-- Aux function for XXTEA
	local MX = function(identificationKeys, z, y, sum, p, e)
		-- (((z >> 5) ^ (y << 2)) + ((y >> 3) ^ (z << 4))) ^ ((sum ^ y) + (keys[((p & 3) ^ e) + 1] ^ z))
		return bitwise_bxor(
			bitwise_bxor(bitwise_rshift(z, 5), bitwise_lshift(y, 2))
			+ bitwise_bxor(bitwise_rshift(y, 3), bitwise_lshift(z, 4))
			, bitwise_bxor(sum, y)
			+ bitwise_bxor(identificationKeys[bitwise_bxor(bitwise_band(p, 3), e) + 1], z)
		)
	end

	--[[@
		@name xxtea
		@desc XXTEA partial 64bits encoder.
		@param self<encode> An Encode object.
		@param data<table> A table with data to be encoded.
		@returns table The encoded data.
	]]
	xxtea = function(self, data)
		local decode = #data

		local y = data[1]
		local z = data[decode]

		local sum = 0

		local e, p
		local q = math_floor(6 + 52 / decode)
		while q > 0 do
			q = q - 1

			sum = bitwise_band((sum + DELTA), LIM)
			e = bitwise_band(bitwise_band(bitwise_rshift(sum, 2), LIM), 3)

			p = 0
			while p < (decode - 1) do
				y = data[p + 2]

				z = bitwise_band((data[p + 1] + MX(self.identificationKeys, z, y, sum, p, e)), LIM)
				data[p + 1] = z

				p = p + 1
			end

			y = data[1]

			z = bitwise_band((data[decode] + MX(self.identificationKeys, z, y, sum, p, e)), LIM)
			data[decode] = z
		end

		return data
	end
end
--[[@
	@name btea
	@desc Encodes a packet with the BTEA block cipher.
	@param packet<byteArray> A Byte Array object to be encoded.
	@returns byteArray The encoded Byte Array object.
]]
encode.btea = function(self, packet)
	local stackLen = packet.stackLen

	if stackLen == 0 then
		return error("↑failure↓[ENCODE]↑ BTEA algorithm can't be applied to an empty byteArray.",
			enum.errorLevel.low)
	end

	while stackLen < 8 do
		stackLen = stackLen + 1
		packet.stack[stackLen] = 0 -- write8 would be slower
	end
	packet.stackLen = stackLen

	local chunks, counter = { }, 0
	while packet.stackLen > 0 do
		counter = counter + 1
		chunks[counter] = packet:read32()
	end

	chunks = xxtea(self, chunks)

	packet = byteArray:new():write16(counter)
	for i = 1, counter do
		packet:write32(chunks[i])
	end

	return packet
end
--[[@
	@name xorCipher
	@desc Encodes a packet using the XOR cipher.
	@desc If @self.hasSpecialRole is true, then the raw packet is returned.
	@param packet<byteArray> A Byte Array object to be encoded.
	@param fingerprint<int> The fingerprint of the encode.
	@returns byteArray The encoded Byte Array object.
]]
encode.xorCipher = function(self, packet, fingerprint)
	if self.hasSpecialRole then
		return packet
	end

	local stack = { }

	for i = 1, packet.stackLen do
		fingerprint = fingerprint + 1
		stack[i] = bit_bxor(packet.stack[i], self.messageKeys[(fingerprint % 20) + 1]) % 256
	end

	return byteArray:new(stack)
end

return encode