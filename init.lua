
local libs = {
	['Windows-x64'] = 'lz4.dll';
	['WIndows-x86'] = 'lz4.dll';
};

local ffi = require('ffi');
local arch = ffi.arch;
local os = ffi.os;
local linker = os..'-'..arch;

local C = module:action('libs/'..linker..'/'..libs[linker], ffi.load);

ffi.cdef[[
	// lz4.h

	//typedef struct		LZ4_stream_t LZ4_stream_t;
	//typedef struct		LZ4_streamDecode_t LZ4_streamDecode_t;

	int					LZ4_versionNumber(void);
	const char*			LZ4_versionString(void);
	int					LZ4_sizeofState(void);

	int					LZ4_compressBound(int inputSize);
	int					LZ4_compress_default(const char* src, char* dst, int srcSize, int dstCapacity);
	int					LZ4_compress_fast(const char* src, char* dst, int srcSize, int dstCapacity, int acceleration);
	int					LZ4_compress_fast_extState(void* state, const char* src, char* dst, int srcSize, int dstCapacity, int acceleration);
	int					LZ4_compress_destSize(const char* src, char* dst, int* srcSizePtr, int targetDstSize);
	int					LZ4_compress_fast_extState_fastReset(void* state, const char* src, char* dst, int srcSize, int dstCapacity, int acceleration);

	int					LZ4_decoderRingBufferSize(int maxBlockSize);
	int					LZ4_decompress_safe(const char* src, char* dst, int compressedSize, int dstCapacity);
	int					LZ4_decompress_safe_usingDict(const char* src, char* dst, int srcSize, int dstCapacity, const char* dictStart, int dictSize);
	int					LZ4_decompress_safe_partial_usingDict(const char* src, char* dst, int compressedSize, int targetOutputSize, int maxOutputSize, const char* dictStart, int dictSize);
	int					LZ4_decompress_safe_partial(const char* src, char* dst, int srcSize, int targetOutputSize, int dstCapacity);

	// Non-binded API

	//LZ4_stream_t*		LZ4_createStream(void);
	//int					LZ4_freeStream(LZ4_stream_t* streamPtr);
	//void				LZ4_resetStream_fast(LZ4_stream_t* streamPtr);
	//int					LZ4_compress_fast_continue(LZ4_stream_t* streamPtr, const char* src, char* dst, int srcSize, int dstCapacity, int acceleration);
	//int					LZ4_loadDict(LZ4_stream_t* streamPtr, const char* dictionary, int dictSize);
	//int					LZ4_saveDict(LZ4_stream_t* streamPtr, char* safeBuffer, int maxDictSize);

	//LZ4_streamDecode_t* LZ4_createStreamDecode(void);
	//int                 LZ4_freeStreamDecode(LZ4_streamDecode_t* LZ4_stream);
	//int					LZ4_setStreamDecode(LZ4_streamDecode_t* LZ4_streamDecode, const char* dictionary, int dictSize);
	//int					LZ4_decompress_safe_continue(LZ4_streamDecode_t* LZ4_streamDecode, const char* src, char* dst, int srcSize, int dstCapacity);

	// lz4hc.h

	//typedef struct		LZ4_streamHC_t LZ4_streamHC_t;

	int					LZ4_sizeofStateHC(void);
	int					LZ4_compress_HC(const char* src, char* dst, int srcSize, int dstCapacity, int compressionLevel);
	int					LZ4_compress_HC_extStateHC(void* stateHC, const char* src, char* dst, int srcSize, int maxDstSize, int compressionLevel);
	int					LZ4_compress_HC_destSize(void* stateHC, const char* src, char* dst, int* srcSizePtr, int targetDstSize, int compressionLevel);

	//LZ4_streamHC_t*		LZ4_createStreamHC(void);
	//int					LZ4_freeStreamHC(LZ4_streamHC_t* streamHCPtr);
	//void				LZ4_resetStreamHC_fast(LZ4_streamHC_t* streamHCPtr, int compressionLevel);   /* v1.9.0+ */
	//int					LZ4_loadDictHC(LZ4_streamHC_t* streamHCPtr, const char* dictionary, int dictSize);
	//int					LZ4_compress_HC_continue(LZ4_streamHC_t* streamHCPtr, const char* src, char* dst, int srcSize, int maxDstSize);
	//int					LZ4_compress_HC_continue_destSize(LZ4_streamHC_t* LZ4_streamHCPtr, const char* src, char* dst, int* srcSizePtr, int targetDstSize);
	//int					LZ4_saveDictHC (LZ4_streamHC_t* streamHCPtr, char* safeBuffer, int maxDictSize);
]];

local versionNumber = function()
	return C.LZ4_versionNumber();
end;

local versionString = function()
	return ffi.string(C.LZ4_versionString());
end;

local sizeofState = function()
	return C.LZ4_sizeofState();
end;

local sizeofStateHC = function()
	return C.LZ4_sizeofStateHC();
end;

local compressBound = function(inputSize)
	return C.LZ4_compressBound(inputSize);
end;

local decoderRingBufferSize = function(maxBlockSize)
	return C.LZ4_decoderRingBufferSize(maxBlockSize);
end;

local compress = function(src, filldest, level, state, acceleration)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = 0;

	if (level) then
		if (state) then
			if (filldest) then
				compressed_length = C.LZ4_compress_HC_destSize(state, src, buffer, ffi.new('int[1]', length_src), buffer_length, level);
			else compressed_length = C.LZ4_compress_HC_extStateHC(state, src, buffer, length_src, buffer_length, level);
			end;
		else compressed_length = C.LZ4_compress_HC(src, buffer, length_src, buffer_length, level);
		end;
	elseif (filldest) then
		compressed_length = C.LZ4_compress_destSize(src, buffer, ffi.new('int[1]', length_src), buffer_length);
	elseif (state) then
		compressed_length = C.LZ4_compress_fast_extState(state, src, buffer, length_src, buffer_length, acceleration or 1);
	elseif (not state and acceleration) then
		compressed_length = C.LZ4_compress_fast(src, buffer, length_src, buffer_length, acceleration);
	else compressed_length = C.LZ4_compress_default(src, buffer, length_src, buffer_length);
	end;

	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;

	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_default = function(src)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_default(src, buffer, length_src, buffer_length);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_fast = function(src, acceleration)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_fast(src, buffer, length_src, buffer_length, acceleration);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_destSize = function(src)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_destSize(src, buffer, ffi.new('int[1]', length_src), buffer_length);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_fast_extState = function(src, state, acceleration)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_fast_extState(state, src, buffer, length_src, buffer_length, acceleration or 1);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_fast_extState_fastReset = function(src, state, acceleration)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_fast_extState_fastReset(state, src, buffer, length_src, buffer_length, acceleration or 1);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_HC = function(src, level)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_HC(src, buffer, length_src, buffer_length, level);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_HC_destSize = function(src, state, level)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_HC_destSize(state, src, buffer, ffi.new('int[1]', length_src), buffer_length, level);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local compress_HC_extStateHC = function(src, state, level)
	local length_src = src:len();
	local buffer_length = length_src;
	local buffer = ffi.new('char[?]', buffer_length);
	local compressed_length = C.LZ4_compress_HC_extStateHC(state, src, buffer, length_src, buffer_length, level);
	if (compressed_length < 0) then
		return nil, 'compress error', compressed_length;
	end;
	local compressed_data = ffi.string(buffer, compressed_length);
	return compressed_data, compressed_length;
end;

local decompress = function(src, buffer_length, targetOutputSize)
	local length_src = src:len();
	local buffer = ffi.new('char[?]', buffer_length);
	local decompressed_length = 0;
	--introduce decompression with dictionaries
	if (targetOutputSize) then
		decompressed_length = C.LZ4_decompress_safe_partial(src, buffer, length_src, targetOutputSize, buffer_length);
	else decompressed_length = C.LZ4_decompress_safe(src, buffer, length_src, buffer_length);
	end;
	if (decompressed_length < 0) then
		return nil, 'decompress error', decompressed_length;
	end;
	local decompressed_data = ffi.string(buffer, decompressed_length);
	return decompressed_data, decompressed_length;
end;

local decompress_safe = function(src, buffer_length)
	local length_src = src:len();
	local buffer = ffi.new('char[?]', buffer_length);
	local decompressed_length = C.LZ4_decompress_safe(src, buffer, length_src, buffer_length);
	if (decompressed_length < 0) then
		return nil, 'decompress error', decompressed_length;
	end;
	local decompressed_data = ffi.string(buffer, decompressed_length);
	return decompressed_data, decompressed_length;
end;

local decompress_safe_partial = function(src, buffer_length, targetOutputSize)
	local length_src = src:len();
	local buffer = ffi.new('char[?]', buffer_length);
	local decompressed_length = C.LZ4_decompress_safe_partial(src, buffer, length_src, targetOutputSize, buffer_length);
	if (decompressed_length < 0) then
		return nil, 'decompress error', decompressed_length;
	end;
	local decompressed_data = ffi.string(buffer, decompressed_length);
	return decompressed_data, decompressed_length;
end;

return {
	versionNumber = versionNumber;
	versionString = versionString;
	sizeofState = sizeofState;
	sizeofStateHC = sizeofStateHC;
	compressBound = compressBound;
	decoderRingBufferSize = decoderRingBufferSize;

	compress = compress;
	compress_default = compress_default;
	compress_fast = compress_fast;
	compress_destSize = compress_destSize;
	compress_fast_extState = compress_fast_extState;
	compress_fast_extState_fastReset = compress_fast_extState_fastReset;
	compress_HC = compress_HC;
	compress_HC_destSize = compress_HC_destSize;
	compress_HC_extStateHC = compress_HC_extStateHC;

	decompress = decompress;
	decompress_safe = decompress_safe;
	decompress_safe_partial = decompress_safe_partial;
};