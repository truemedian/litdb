exports.name = "Luvit Odoo Connector"
exports.version = "0.0.1"

local http = require("http")
local table = require("table")
local rpc = require("json-rpc")
local string = require("string")
string.split = function(inputstr, sep)
	if sep == nil then
		sep = "%s"
    end

    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    	t[i] = str
      i = i + 1
    end
    return t
end



exports.new = function(config)
	local this = {}

	config = config or {}

	this.host = config.host
	this.port = config.port or 80
	this.db = config.db
	this.user = config.user
	this.pw = config.pw


	this.connect = function(self, cb)
		local params = {
			db = self.db,
			login = self.user,
			password = self.pw
		}

		local options = {
			host = self.host,
			port = self.port,
			path = "/web/session/authenticate",
			data = {
				db = self.db,
				login = self.user,
				password = self.pw 
			}
		}

		rpc.request(options, function(err, res)
			if err then return cb(err) end

			if res.error then return cb(res.error) end

			self.uid = res.result.uid
			self.session_id = res.result.session_id
			self.sid = "session_id=" .. self.session_id
			self.context = res.result.user_context

			cb(nil, res.result)
		end)

		return self
	end

	this.request = function(self, path, params, cb)
		local params = params or {}

		local options = {
			host = self.host,
			port = self.port,
			path = path or "/",
			data = params,
			headers = {Cookie = self.sid .. ";"}
		}

		rpc.request(options, function(err, res)
			if err then
				return cb(err)
			end

			cb(nil, res)
		end)

		return self
	end

	this.get = function(self, model, id, cb)
		self:request("/web/dataset/call", {
			method = "read",
			model = model,
			args = {id}
		}, cb)
	end

	this.create = function(self, model, params, cb)
		self:request("/web/dataset/call_kw", {
			kwargs = {
				context = self.context
			},
			method = "create",
			model = model,
			args = {params}
		}, cb)
	end

	this.update = function(self, model, id, params, cb)
		self:request("/web/dataset/call_kw", {
			kwargs = {
				context = self.context
			},
			method = "write",
			model = model,
			args = {{id}, params}
		}, cb)
	end

	this.delete = function(self, model, id, cb)
		self:request("/web/dataset/call_kw", {
			kwargs = {
				context = self.context
			},
			method = "unlink",
			model = model,
			args = {{id}}
		}, cb)
	end

	this.search = function(self, model, params, cb)
		self:request("/web/dataset/call_kw", {
			kwargs = {
				context = self.context
			},
			method = "search",
			model = model,
			args = {params}
		}, cb)
	end

	return this
end