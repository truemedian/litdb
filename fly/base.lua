if process.env["FLIGHT_MODE"] == "on" then
	return require "./production"
else
	return require "./development"
end