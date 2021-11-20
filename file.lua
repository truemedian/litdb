--[[lit-meta
	name = "RiskoZoSlovenska/simple-http"
	version = "1.1.0"
	homepage = "https://github.com/RiskoZoSlovenska/simple-http"
	description = "A basic, high-level wrapper for coro-http."
	tags = {"http", "coro", "wrapper"}
	dependencies = {
		"creationix/coro-http@3.2.3",
		"creationix/schema@1.1.0"
	}
	license = "MIT"
	author = "RiskoZoSlovenska"
]]

local http = require("coro-http")
local json = require("json")
local querystring = require("querystring")
local schemaLib = require("schema")

local match, lower, format = string.match, string.lower, string.format
local insert = table.insert

local Encoding = {
	json = "application/json",
	url  = "application/x-www-form-urlencoded",
}

local FailReason = {
	Unknown = 0,
	BadPayload = 1,
	RequestError = 2,
	BadResponseCode = 3,
	BadResponseBody = 4,
	InvalidResponseBody = 5,
}



-- Assumes func never returns more than two values, and that a valid return won't ever be false or nil
local function customPcall(func, ...)
	local success, res1, res2 = xpcall(func, debug.traceback, ...)

	if success then
		return res1, res2
	else
		return nil, res1
	end
end

local function matchContentType(typeString)
	return match(typeString, "^([%a%-]+/[%a%-]+)")
end

local function normalizeHeaders(tbl)
	local normalized = {}

	for i = 1, #tbl do
		normalized[i] = tbl[i]
	end

	for k, v in pairs(tbl) do
		if not normalized[k] then -- Check whether we already assigned this one
			insert(normalized, {k, v})
		end
	end

	return normalized
end

local function findHeader(headers, query)
	for i = 1, #headers do
		local header = headers[i]

		if lower(header[1]) == query then
			return header, i
		end
	end

	return nil, nil
end

local function getEncodingFromHeaders(headers)
	local typeHeader = findHeader(headers, "content-type")
	if typeHeader then
		local contentType = matchContentType(typeHeader[2])
		return contentType and lower(contentType) or nil
	end
end

local function buildErrInfo(enum, errTrace, body, response)
	return {
		type = enum or FailReason.Unknown,
		trace = errTrace,
		body = body,
		response = response,
	}
end



local encoders = {
	[Encoding.json] = json.encode,
	[Encoding.url]  = querystring.stringify,
}
local decoders = {
	[Encoding.json] = json.decode,
	[Encoding.url]  = querystring.parse,
}
local function request(method, url, payload, encoding, headers, schema, options)
	headers = headers and normalizeHeaders(headers) or {}


	-- Encode payload
	local shouldEncode = (encoding ~= nil or payload ~= nil)

	local encoded, encodeError
	if shouldEncode then
		encoded, encodeError = customPcall(encoders[encoding] or tostring, payload)

		if not encoded then
			return nil, "Bad payload: Failed to encode", buildErrInfo(
				FailReason.BadPayload,
				encodeError,
				payload, nil
			)
		end
	end

	-- Insert encoding header
	if encoding and not findHeader(headers, "content-type") then
		insert(headers, {"Content-Type", encoding})
	end


	-- Make request
	local res, body = customPcall(
		http.request, method, url, headers, encoded, options
	)

	if not res then
		return nil, "Sending request failed", buildErrInfo(
			FailReason.RequestError,
			body,
			nil, nil
		)

	elseif res.code >= 300 then
		return nil, "Request failed: " .. res.code .. ": " .. res.reason, buildErrInfo(
			FailReason.BadResponseCode,
			nil,
			body, res
		)
	end


	-- Decode response
	local decoding = getEncodingFromHeaders(res)
	local decoded, decodeErr = customPcall(decoders[decoding] or tostring, body)

	if not decoded then
		return nil, "Bad response body: Failed to decode", buildErrInfo(
			FailReason.BadResponseBody,
			decodeErr,
			body, res
		)
	end

	-- Typecheck result
	if schema then
		local name, expected, actual = schema("body", decoded)

		if actual then
			local err = format("Bad response %s: Expected %s, got %s", name, expected, actual)
			return nil, err, buildErrInfo(
				FailReason.InvalidResponseBody,
				nil,
				decoded, res
			)
		end
	end

	return decoded, res, nil
end



return {
	request = request,

	Encoding = Encoding,
	FailReason = FailReason,

	coroHttp = http,
	json = json,
	querystring = querystring,
	schema = schemaLib,
}