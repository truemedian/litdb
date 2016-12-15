local errors = {
	["400"] = "Bad Request",
	["401"] = "Unauthorized – Your Application/User application key is wrong.",
	["403"] = "Forbidden.",
	["404"] = "Not Found.",
	["405"] = "Method Not Allowed.",
	["406"] = "Not Acceptable.",
	["429"] = "Too Many Requests.",
	["500"] = "Internal Server Error – We had a problem with our server. Try again later.",
	["503"] = "Service Unavailable – We’re temporarially offline for maintanance. Please try again later.",

}

function Error(err)
	return errors[err]()
end

return Error