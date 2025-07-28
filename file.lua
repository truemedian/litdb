--[[lit-meta
    name = "Richy-Z/base32"
    version = "0.1.5"
    dependencies = {}
    description = "Base32 implementation for Luvit"
    tags = { "base32", "rfc4648", "encoding", "decoding" }
    license = "Apache 2"
    author = { name = "Richard Ziupsnys", email = "hello@richy.lol" }
    homepage = "https://github.com/Richy-Z/luvit-batteries"
  ]]

-- compliant as per RFC 4648
-- https://datatracker.ietf.org/doc/html/rfc4648

local _BASE32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

local lshift = bit.lshift
local rshift = bit.rshift

local bor = bit.bor
local band = bit.band

local insert = table.insert
local concat = table.concat

local rep = string.rep
local char = string.char

-- "Implementations MUST include appropriate pad characters..."
-- omitted optional padding argument, but otherwise here and working if required

-- Encodes a string into Base32 according to [RFC 4648](https://datatracker.ietf.org/doc/html/rfc4648).
--
-- - Padding with `=` is always added, as per the specification.
-- - Case is always uppercased.
-- - Output is a plain string.
--
-- ```lua
-- print(base32.encode("foobar")) -- MZXW6YTBOI======
--
-- assert(encode("foobar") == "MZXW6YTBOI======")
-- ```
---@param str string
---@return string
local function encode(str --[[, padding]])
    local output = {}
    local buffer = 0
    local remaining = 0

    for i = 1, #str do
        buffer = bor(lshift(buffer, 8), str:byte(i))
        remaining = remaining + 8

        while remaining >= 5 do
            local index = band(rshift(buffer, remaining - 5), 0x1F)
            remaining = remaining - 5
            insert(output, _BASE32:sub(index + 1, index + 1))
        end
    end

    -- handle the bits that were left over
    if remaining > 0 then
        local index = band(lshift(buffer, 5 - remaining), 0x1F)
        insert(output, _BASE32:sub(index + 1, index + 1))
    end

    local encoded = concat(output)

    --if padding then
    local remainder = #encoded % 8
    if remainder > 0 then
        encoded = encoded .. rep("=", 8 - remainder)
    end
    --end

    return encoded
end

local _DECODE_MAP = {}
for i = 1, #_BASE32 do
    local c = _BASE32:sub(i, i)
    _DECODE_MAP[c] = i - 1
end

-- Decodes a Base32 string into its original content.
--
-- - Whitespace and padding are stripped automatically from the input string.
-- - Returns `nil, errorStr` if invalid Base32 characters are encountered.
--
-- ```lua
-- print(base32.decode("MZXW6YTBOI======")) -- foobar
--
-- print(base32.decode("MZXW6 YT B O I======")) -- foobar
--
-- assert(decode("M  ZX W6Y    TBOI======") == "foobar")
--
-- local ok, err = base32.decode("??")
-- assert(not ok)
-- print(err) -- Invalid base32 character: ?
-- ```
---@param str string
---@return string?
---@return string?
local function decode(str)
    str = str:gsub("[%s=]", ""):upper() -- strip padding and whitespace
    local buffer = 0
    local bits = 0
    local output = {}

    for i = 1, #str do
        local c = str:sub(i, i)
        local val = _DECODE_MAP[c]
        if not val then
            return nil, "Invalid base32 character: " .. tostring(c)
        end

        buffer = bor(lshift(buffer, 5), val)
        bits = bits + 5

        if bits >= 8 then
            bits = bits - 8
            local byte = band(rshift(buffer, bits), 0xFF)
            insert(output, char(byte))
        end
    end

    return concat(output)
end

-- TESTS

-- https://datatracker.ietf.org/doc/html/rfc4648#section-10
-- BASE32("foo") = "MZXW6==="
-- BASE32("foob") = "MZXW6YQ="
-- BASE32("fooba") = "MZXW6YTB"
-- BASE32("foobar") = "MZXW6YTBOI======"

assert(encode("foo") == "MZXW6===")
assert(encode("foob") == "MZXW6YQ=")
assert(encode("fooba") == "MZXW6YTB")
assert(encode("foobar") == "MZXW6YTBOI======")

assert(decode("MZXW6===") == "foo")
assert(decode("MZXW6YQ=") == "foob")
assert(decode("MZXW6YTB") == "fooba")
assert(decode("MZXW6YTBOI======") == "foobar")

local _testStr = "numelon ltd. loves luvit <3"
local _testEncoded = encode(_testStr)
local _testDecoded = decode(_testEncoded)

assert(_testDecoded == _testStr)
assert(encode(_testDecoded) == _testEncoded) ---@diagnostic disable-line: param-type-mismatch

-- export
return {
    encode = encode,
    decode = decode
}
