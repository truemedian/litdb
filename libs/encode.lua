local byteArray = require("bArray")
local bitwise = require("bitwise")

local getPasswordHash
do
	local openssl = require("openssl") -- built-in
	local sha256 = openssl.digest.get("sha256")

	-- Aux function to getPasswordHash
	local cryptToSha256 = function(str)
		local hash = openssl.digest.new(sha256)
		hash:update(str)
		return hash:final()
	end

	local saltBytes = {
		247, 026, 166, 222,
		143, 023, 118, 168,
		003, 157, 050, 184,
		161, 086, 178, 169,
		062, 221, 067, 157,
		197, 221, 206, 086,
		211, 183, 164, 005,
		074, 013, 008, 176
	}
	do
		local chars = { }
		for i = 1, #saltBytes do
			chars[i] = string.char(saltBytes[i])
		end

		saltBytes = table.concat(chars)
	end

	local base64 = require("base64") -- built-in
	--[[@
		@desc Encrypts the account's password.
		@param password<string> The account's password.
		@returns string The encrypted password.
	]]
	getPasswordHash = function(password)
		local hash = cryptToSha256(password)
		hash = cryptToSha256(hash .. saltBytes)
		local len = #hash

		local out, counter = { }, 0
		for i = 1, len, 2 do
			counter = counter + 1
			out[counter] = string.char(tonumber(string.sub(hash, i, (i + 1)), 16))
		end

		return base64.encode(table.concat(out))
	end
end

local identificationKeys = { }
local messageKeys = { }

--[[@
	@desc Sets the packet keys.
	@param idKeys<table> The identification keys of the SWF/endpoint.
	@param msgKeys<table> The message keys of the SWF/endpoint.
]]
local setPacketKeys = function(idKeys, msgKeys)
	identificationKeys = idKeys
	messageKeys = msgKeys
end

local xxtea
do
	local DELTA, LIM = 0x9E3779B9, 0xFFFFFFFF

	-- Aux function for XXTEA
	local MX = function(z, y, sum, p, e)
		-- (((z >> 5) ^ (y << 2)) + ((y >> 3) ^ (z << 4))) ^ ((sum ^ y) + (keys[((p & 3) ^ e) + 1] ^ z))
		return bitwise.bxor(bitwise.bxor(bitwise.rshift(z, 5), bitwise.lshift(y, 2)) + bitwise.bxor(bitwise.rshift(y, 3), bitwise.lshift(z, 4)), bitwise.bxor(sum, y) + bitwise.bxor(identificationKeys[bitwise.bxor(bitwise.band(p, 3), e) + 1], z))
	end

	--[[@
		@desc XXTEA partial 64bits encoder.
		@param data<table> A table with data to be encoded.
		@returns table The encoded data.
	]]
	xxtea = function(data)
		local decode = #data

		local y = data[1]
		local z = data[decode]

		local sum = 0

		local e, p
		local q = math.floor(6 + 52 / decode)
		while q > 0 do
			q = q - 1

			sum = bitwise.band((sum + DELTA), LIM)
			e = bitwise.band(bitwise.band(bitwise.rshift(sum, 2), LIM), 3)

			p = 0
			while p < (decode - 1) do
				y = data[p + 2]

				z = bitwise.band((data[p + 1] + MX(z, y, sum, p, e)), LIM)
				data[p + 1] = z

				p = p + 1
			end

			y = data[1]

			z = bitwise.band((data[decode] + MX(z, y, sum, p, e)), LIM)
			data[decode] = z
		end

		return data
	end
end

--[[@
	@desc Encodes a packet with the BTEA block cipher.
	@param packet<byteArray> A Byte Array object to be encoded.
	@returns byteArray The encoded Byte Array object.
]]
local btea = function(packet)
	local stackLen = #packet.stack

	if stackLen == 0 then
		return error("↑failure↓[ENCODE]↑ BTEA algorithm can't be applied to an empty byteArray.", enum.errorLevel.low)
	end

	while stackLen < 8 do
		stackLen = stackLen + 1
		packet.stack[stackLen] = 0
	end

	packet = byteArray:new(packet.stack) -- Saves resource, instead of using write8

	local chunks, counter = { }, 0
	while #packet.stack > 0 do
		counter = counter + 1
		chunks[counter] = packet:read32()
	end

	chunks = xxtea(chunks)

	packet:write16(#chunks)
	for i = 1, #chunks do
		packet:write32(chunks[i])
	end

	return packet
end

--[[@
	@desc Encodes a packet using the XOR cipher.
	@param packet<byteArray> A Byte Array object to be encoded.
	@param fingerprint<int> The fingerprint of the encode.
	@returns byteArray The encoded Byte Array object.
]]
local xorCipher = function(packet, fingerprint)
	local stack = { }

	for i = 1, #packet.stack do
		fingerprint = fingerprint + 1
		stack[i] = bit.band(bit.bxor(packet.stack[i], messageKeys[(fingerprint % 20) + 1]), 255)
	end

	return byteArray:new(stack)
end

return {
	getPasswordHash = getPasswordHash,
	setPacketKeys = setPacketKeys,
	btea = btea,
	xorCipher = xorCipher
}