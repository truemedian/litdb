--[[lit-meta
name = 'kaustavha/luvit-dead-beef-rand'
version = '2.0.0'
license = 'MIT'
homepage = "https://github.com/kaustavha/luvit-dead-beef-rand"
description = "Deadbeef random based PRNG"
tags = {"luvit", "crypto" }
dependencies = { 
  "luvit/luvit@2"
}
author = { name = 'Kaustav Haldar'}
]]
local bit = require('bit')
local xor = bit.bxor
local lshift = bit.lshift
local rshift = bit.rshift

return function(seed)
  assert(seed, 'Need a seed')
  local beef = 0xdeadbeef
  seed = xor(lshift(seed, 7), (rshift(seed, 25) + beef))
  beef = xor(lshift(beef, 7), (rshift(beef, 7) + 0xdeadbeef))
  return seed % 0x100000000
end

