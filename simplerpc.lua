local json = require"json"

return function (path, port)
	local simplerpc = {
		connections = {}
	}

	function simplerpc:handlejsonrpcrequest(ws, msg, payload)
		if not self[payload.method] then return end

		local res = self[payload.method](unpack(payload.params))

		if not payload.id then return end

		msg.payload = json.stringify{
			jsonrpc = "2.0",
			result = res,
			id = msg.id
		}
		msg.mask = nil

		ws.writer(msg)
	end

	function simplerpc:makejsonrpcrequest(ws, method, cb, ...)
		local params = {...}
		if #params == 1 then
			params = params[1]
		end

		ws.writer{
			opcode = 1,
			payload = json.stringify{
				jsonrpc = "2.0",
				method = method,
				params = params,
				id = ws.indexer
			}
		}
		ws.running[ws.indexer] = cb

		ws.indexer = ws.indexer + 1
	end

	function simplerpc:handlejsonresponse(ws, msg, payload)
		if not ws.running[payload.id] then return end

		if payload.error then
			print("SimpleRPC error on method call "..payload.id..": "..payload.message)
			ws.running[payload.id]()
		else
			if type(payload.result == "table") then
				ws.running[payload.id](unpack(payload.result))
			else
				ws.running[payload.id](payload.result)
			end
		end
		ws.running[payload.id] = nil
	end

	function simplerpc:handlemsg(ws, msg, payload)
		if payload.method then
			self:handlejsonrpcrequest(ws, msg, payload)
		elseif payload.id and ws.running[payload.id] then
			if payload.error or payload.result then
				self:handlejsonresponse(ws, msg, payload)
			end
		end
	end

	local weblit = require "weblit"

	weblit.app.bind{
		port = port or 80
	}

	weblit.app.use(require"weblit-logger")
	weblit.app.use(require"weblit-auto-headers")
	weblit.app.use(require"weblit-etag-cache")

	weblit.app.use(weblit.websocket({
		path = path or "/"
	}, function(req, read, write)
		print("New Connection!")

		table.insert(simplerpc.connections, setmetatable({
			writer = write,
			running = {},
			indexer = 0,
			template = {
				fin = true,
				opcode = 1
			}
		}, {
			__index = function(tab, key)
				return function(cb, ...)
					simplerpc:makejsonrpcrequest(tab, key, cb, ...)
				end
			end
		}))

		local pos = #simplerpc.connections
		local me = simplerpc.connections[pos]

		if simplerpc.onconnection then
			simplerpc.onconnection(me)
		end

		for message in read do
			if message then
				simplerpc:handlemsg(me, message, json.parse(message.payload))
			end
		end

		table.remove(simplerpc.connections, pos)

		print("closed: ", pos)

		write()
	end))

	simplerpc.weblit = weblit

	return setmetatable(simplerpc, {
		__index = function(tab, key)
			return function(...)

			end
		end
	})
end
