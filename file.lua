--[[lit-meta
	name = "RiskoZoSlovenska/simple-http"
	version = "1.0.0"
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
local schema = require("schema")

local match, lower, format = string.match, string.lower, string.format
local insert = table.insert
local pairs = pairs
local tostring = tostring
local type = type
local pcall = pcall

local Encoding = {
	json = "application/json",
	url  = "application/x-www-form-urlencoded",
}



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


local encoders = {
	[Encoding.json] = json.encode,
	[Encoding.url]  = querystring.stringify,
}
local decoders = {
	[Encoding.json] = json.decode,
	[Encoding.url]  = querystring.parse,
}
local function request(method, url, payload, encoding, headers, schema, options)
	encoding = encoding or Encoding.json
	headers = headers and normalizeHeaders(headers) or {}

	-- Insert Content-Type header
	if not findHeader(headers, "content-type") then
		insert(headers, {"Content-Type", encoding})
	end

	-- Encode payload
	if payload ~= nil and type(payload) ~= "string" then
		payload = (encoders[encoding] or tostring)(payload)
	end


	-- Make request
	local success, res, body = pcall(
		http.request, method, url, headers, payload, options
	)


	-- Handle errors
	if not success then
		return nil, "Sending request failed: " .. tostring(res), nil

	elseif res.code >= 300 then
		return nil, res.code .. ": " .. res.reason, res
	end


	-- Decode response
	do
		local decoding
		local typeHeader = findHeader(res, "content-type")
		if typeHeader then
			decoding = lower(matchContentType(typeHeader[2]))
		end

		local decodeSuccess
		decodeSuccess, body = pcall(decoders[decoding] or tostring, body)

		if not decodeSuccess then
			return nil, "Invalid response body: Failed to decode", body
		end
	end

	-- Typecheck result
	if schema then
		local name, expected, actual = schema("body", body)
		if actual then
			return nil, format(
				"Invalid response %s: Expected %s, got %s",
				name, expected, actual
			), body
		end
	end

	return body, res, nil
end



return {
	request = request,
	Encoding = Encoding,

	coroHttp = http,
	json = json,
	querystring = querystring,
	schema = schema,
}