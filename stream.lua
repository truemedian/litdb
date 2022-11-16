
local ffi = require('ffi');

local C = ffi.C;

local enc = {};

enc.compress = function(self)
	C.LZ4_compress_fast_continue(self, src, srclen or #src, dst, dstlen or #dst, accel or 1)
end;

enc.free = function(self)
	ffi.gc(self, nil)
	C.LZ4_freeStream(self)
end;

enc.__index = enc;

return enc;