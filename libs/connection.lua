local net_createConnection = require("net").createConnection
local timer_setTimeout = require("timer").setTimeout

local byteArray = require("bArray")
local buffer = require("buffer")
local enum = require("enum")

-- Optimization --
local bit_band = bit.band
local bit_bor = bit.bor
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local string_format = string.format
local string_getBytes = string.getBytes
local table_add = table.add
local table_concat = table.concat
local table_fuse = table.fuse
local table_join = table.join
local table_setNewClass = table.setNewClass
local table_unpack = table.unpack
local table_writeBytes = table.writeBytes
------------------

local connection = table_setNewClass()

--[[@
	@name new
	@desc Creates a new instance of Connection.
	@param name<string> The connection name, for referece.
	@param event<Emitter> An event emitter object.
	@returns connection The new Connection object.
	@struct {
		event = { }, -- The event emitter object, used to trigger events.
		socket = { }, -- The socket object, used to create the connection between the bot and the game.
		buffer = { }, -- The buffer object, used to control the packets flow when received by the socket.
		ip = "", -- IP of the server where the socket is connected. Empty if it is not connected.
		packetID = 0, -- An identifier ID to send the packets in the correct format.
		port = 1, -- The index of one of the ports from the enumeration 'ports'. It gets constant once a port is accepted in the server.
		name = "", -- The name of the connection object, for reference.
		open = false, -- Whether the connection is open or not.
		_isReadingStackLength = true, -- Whether the connection is reading the length of the received packet or not.
		_readStackLength = 0, -- Length read at the moment.
		_lengthBytes = 0 -- Number of bytes read (real value needs a divison by 7).
	}
]]
connection.new = function(self, name, event)
	return setmetatable({
		event = event,
		socket = nil,
		buffer = buffer:new(),
		ip = "",
		packetID = 0,
		port = 1,
		name = name,
		open = false,
		_isReadingStackLength = true,
		_readStackLength = 0,
		_lengthBytes = 0
	}, connection)
end
--[[@
	@name close
	@desc Ends the socket connection.
]]
connection.close = function(self)
	self.open = false
	self.socket:destroy()
	--[[@
		@name disconnection
		@desc Triggered when a connection dies or fails.
		@param connection<connection> The connection object.
	]]
	self.event:emit("disconnection", self)
end

--[[@
	@name connect
	@desc Creates a socket to connect to the server of the game.
	@param ip<string> The server IP.
	@param port?<int> The server port. If nil, all the available ports are going to be used until one gets connected.
]]
connection.connect = function(self, ip, port)
	local hasPort = not not port
	if not hasPort then
		port = enum.setting.port[self.port]
	end

	local socket
	socket = net_createConnection(port, ip, function()
		self.socket = socket

		self.ip = ip
		self.open = true

		socket:on("data", function(data)
			self.buffer:push(data)
		end)

		--[[@
			@name _socketConnection
			@desc Triggered when the socket gets connected.
			@param connection<connection> The connection.
			@param port<int> The port where the socket got connected.
		]]
		self.event:emit("_socketConnection", self, port)
	end)

	timer_setTimeout(3500, function()
		if not self.open then
			if not hasPort then
				self.port = self.port + 1
				if self.port <= #enum.setting.port then
					return self:connect(ip)
				end
			end
			return error("↑error↓[SOCKET]↑ Timed out.", enum.errorLevel.high)
		end
	end)
end
--[[@
	@name receive
	@desc Retrieves the data received from the server.
	@returns table,nil The bytes that were removed from the buffer queue. Can be nil if the queue is empty or if a packet is only partially received.
]]
connection.receive = function(self)
	local byte
	while self._isReadingStackLength and not self.buffer:isEmpty() do
		byte = self.buffer:receive(1)[1]
		-- r | (b&0x7F << l)
		self._readStackLength = bit_bor(self._readStackLength, bit_lshift(bit_band(byte, 0x7F), self._lengthBytes))
		-- Using multiples of 7 saves unnecessary multiplication in the formula above
		self._lengthBytes = self._lengthBytes + 7

		self._isReadingStackLength = (self._lengthBytes < 35 and bit_band(byte, 0x80) == 0x80)
	end

	if not self._isReadingStackLength and self.buffer._count >= self._lengthBytes then
		local byteArr = self.buffer:receive(self._readStackLength)

		self._isReadingStackLength = true
		self._readStackLength = 0
		self._lengthBytes = 0

		return byteArr
	end
end
--[[@
	@name send
	@desc Sends a packet to the server.
	@param identifiers<table> The packet identifiers in the format (C, CC).
	@param alphaPacket<byteArray,string,number> The packet ByteArray, ByteString or byte to be sent to the server.
]]
connection.send = function(self, identifiers, alphaPacket)
	local betaPacket
	if type(alphaPacket) == "table" then
		if alphaPacket.stack then
			betaPacket = byteArray:new(table_fuse(identifiers, alphaPacket.stack))
		else
			local bytes = { "0x" .. (string_format("%02x", identifiers[1]) .. string_format("%02x", identifiers[2])), 0x1, table_join(alphaPacket, 0x1) }
			betaPacket = byteArray:new():write8(1, 1):writeUTF(bytes)
		end
	elseif type(alphaPacket) == "string" then
		betaPacket = byteArray:new(table_fuse(identifiers, string_getBytes(alphaPacket)))
	elseif type(alphaPacket) == "number" then
		local arg = { table_unpack(identifiers) }
		arg[#arg + 1] = alphaPacket

		betaPacket = byteArray:new():write8(table_unpack(arg))
	else
		return error("↑failure↓[SEND]↑ Unknown packet type.\n\tIdentifiers: " .. table_concat(identifiers, ','), enum.errorLevel.low)
	end

	local gammaPacket = byteArray:new()

	local stackLen = #betaPacket.stack
	local stackType = bit_rshift(stackLen, 7)
	while stackType ~= 0 do
		gammaPacket:write8(bit_bor(bit_band(stackLen, 0x7F), 0x80)) -- s&0x7F | 0x80
		stackLen = stackType
		stackType = bit_rshift(stackLen, 7)
	end
	gammaPacket:write8(bit_band(stackLen, 0x7F))

	gammaPacket:write8(self.packetID)
	self.packetID = (self.packetID + 1) % 100

	table_add(gammaPacket.stack, betaPacket.stack)

	local written = self.socket and self.socket:write(table_writeBytes(gammaPacket.stack))
	if not written then
		self.open = false
		if self.ip ~= enum.setting.mainIp then -- Avoids that 'disconnection' gets triggered twice when it is the main instance.
			self.event:emit("disconnection", self)
			return
		end
	end

	--[[@
		@name send
		@desc Triggered when the client sends packets to the server.
		@param identifiers<table> The C, CC identifiers sent in the request.
		@param packet<byteArray> The Byte Array object that was sent.
	]]
	self.event:emit("send", identifiers, alphaPacket)
end

return connection