local bah = require("./keys")
local keys = bah[1]
local funcs=bah[2]

local runner = {}

function runner:st(a, b)
	self.runningVars[a+1]=b
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({1, a+1, b}) end
	return self
end

function runner:gt(a)
	if self.debug then _G[self.id]:updated({2, a+1}) end
	return self.runningVars[a+1]
end

function runner:mv(a, b, c)
	if c then
		self.processVar[b+1]=self.runningVars[a+1]
	else
		self.runningVars[b+1]=self.runningVars[a+1]
	end
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({3, a+1, b+1, c}) end
	return self
end

function runner:rm(a)
	self.runningVars[a+1]=nil
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({4, a+1}) end
	return self
end

function runner:sz(a)
	if a then return #self.runningVars[a+1] else return #self.runningVars end
end

function runner:ps(a, b)
	self.processVar[a+1]=b
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({5, a+1, b}) end
	return self
end

function runner:pg(a)
	if self.debug then _G[self.id]:updated({6, a+1}) end
	return self.processVar[a+1]
end

function runner:pm(a, b, c)
	if c then
		self.runningVars[b+1]=self.processVar[a+1]
	else
		self.processVar[b+1]=self.processVar[a+1]
	end
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({6, a+1, b+1, c}) end
	return self
end

function runner:pr(a)
	self.processVar[a+1]=nil
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({7, a+1}) end
	return self
end

function runner:pz(a)
	if a then return #self.processVar[a+1] else return #self.processVar end
end

function runner:ap()
	self.pos=self.pos+1
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({0, self.pos-1}) end
	return self.pos
end

function runner:aq(a)
	self.pos=self.pos+a
	if self.debug then _G[self.id]:update(self) _G[self.id]:updated({0, self.pos-a}) end
	return self.pos
end

function runner:gb(a)
	self.archive:seek("set", a)
	local b=string.byte(self.archive:read(1))
	self.archive:seek("set", self.pos)
	return b
end

function runner:na(a)
	if not a then a=1 end
	self.archive:seek("set", self.pos+a)
	local b = string.byte(self.archive:read(1))
	self.archive:seek("set", self.pos)
	return b
end

function runner:sp(a)
	self.pos=a
	self.archive:seek("set", self.pos)
	return self.pos
end

function runner:af(a, b)
	self.funcs[a+1]=b
	return self.funcs[a+1]
end

function runner:open(a)
	if a then self.archive=a end
	self.archive=io.open(self.archive, 'rb')
	return self
end

function runner:interpreter(a)
	return self.funcs[a+1](self)
end

function runner:execnext()
	if type(self.archive)~='userdata' then return end
	self.archive:seek("set", self.pos)
	local b=self.archive:read(1)
	if b then
		local a=self:interpreter(string.byte(b))
		self:ap()
		return a
	else
		return nil
	end
end

local function createRunner(a)
	local c = {runningVars={}, processVar={}, archive="main.skl", funcs=funcs, pos=0}
	setmetatable(c, {__index=runner})
	local b=""
	if a then
		b=tostring(math.random())
		_G[b]={
			pn=0,
			rv={},
			pv={},
			updated=a,
			id=b
		}
		setmetatable(_G[b], {__index={
		update=function(self, a)
			self.pn=a.pos
			self.rv=a.runningVars
			self.pv=a.processVar
		end,
		updated=function(self, a)
			self.updated(self, a)
		end
		}})
	end
	c.debug=not not a
	c.id=b
	c:ps(3, require("valuesType"):new())
	c:ps(4, false)
	return c
end

function runner:new(a)
	local b = createRunner(a)
	return b
end

return createRunner