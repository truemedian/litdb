-- converted from https://github.com/crypto-utils/rndm

local math = require("math")
local Buffer = require("buffer").Buffer

local function create (chars)
  assert(type(chars) == "string", "the list of characters must be a string!")
  local length = Buffer:new(chars).length
  return function (len)
    len = len or 10
    assert(type(len) == "number" and len >= 0, "the length of the random string must be a number!")
    local salt = ""
    local chararr = {}
    chars:gsub(".", function(c) table.insert(chararr, c) end)
    local function getRandomChar()
      return chararr[math.floor(length * math.random())] or getRandomChar()
    end
    for i = 1, len do
      salt = salt .. getRandomChar()
    end
    return salt
  end
end

local base62string = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local base36string = "abcdefghijklmnopqrstuvwxyz0123456789"
local base10string = "0123456789"

local function base62( len )
  return create(base62string)(len)
end

local function base36 ( len )
  return create(base36string)(len)
end

local function base10 ( len )
  return create(base10string)(len)
end

local function ecreate ( chars, len )
  return create(chars)(len)
end

return {
  create = ecreate,
  base62 = base62,
  base36 = base36,
  base10 = base10
}