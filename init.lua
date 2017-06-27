local names = {
  ["Linux-x64"] = "luatweetnacl.so",
}
local ffi = require 'ffi'
local arch = ffi.os .. "-" .. ffi.arch
assert(names[arch], "No prebuilt binary for luatweetnacl for " .. arch)

return require('./' .. arch .. '/' .. names[arch])
