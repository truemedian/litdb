local names = {
  ["BSD-x64"] = "libtermbox.so",
  ["Linux-arm"] = "libtermbox.so",
  ["Linux-x64"] = "libtermbox.so",
  ["OSX-x64"] = "libtermbox.dylib",
}

local ffi = require('ffi')
ffi.cdef(module:load("termbox.h"))

local arch = ffi.os .. "-" .. ffi.arch
return module:action(arch .. "/" .. names[arch], function (path)
  return ffi.load(path)
end)
