exports.name = 'kaustavha/luvit-dead-beef-rand'
exports.version = "1.0.1"
exports.license = "Apache 2"
exports.homepage = "https://github.com/kaustavha/luvit-dead-beef-rand/blob/master/deadBeefRand.lua"
exports.description = "PRNG based on deadbeef"
exports.tags = {"luvit", "random", "deadbeef"}

local bit = require('bit')
local xor = bit.bxor
local lshift = bit.lshift
local rshift = bit.rshift

exports.rand = function(seed)
  assert(seed, 'Need a seed')
  local beef = 0xdeadbeef
  seed = xor(lshift(seed, 7), (rshift(seed, 25) + beef))
  beef = xor(lshift(beef, 7), (rshift(beef, 7) + 0xdeadbeef))
  return seed % 0x100000000
end

