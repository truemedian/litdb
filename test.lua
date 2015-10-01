local odooluv = require("../luvit-odoo")


local odoo = odooluv.new({
	host = "odoo.baltray.org",
	port = "80",
	db = "WMM",
	user = "admin@baltray.org",
	pw = "WMM4eVeR1734"
})

odoo:connect(function(err, result)
	if err then
		return print("Connection Error:", err)
	end

--[[
	odoo:request("/web/dataset/call", {
		method = "read",
		model = "res.partner",
		args = {1}
	},function(err, result)
		print(err, "-", result)
		for k,v in pairs(result) do
			print("", k, v)
			if type(v) == "table" then
				for i,j in pairs(v) do
				print("","",i,j)
			end
			end
		end
	end)
	]]

	odoo:update("res.partner", 1, {name = "BALTRAY Corp."}, function(err, cb)
		print(err, cb)
	end)
end)
