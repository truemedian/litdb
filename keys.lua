local values = require("./valuesType")
local retorno = 0
local funcao = 1
local args = 2
local cn = 3
local doif = 4

local valuesfuncs = {
	[3]=function(a)
		a:ap()
		local b = a:interpreter(a:na(0))
		return b:size()
	end,
	[6]=function(a)
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		a:ap()
		return c:set(b, a:interpreter(a:na(0)))
	end,
	[7]=function(a)
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		return c:value(b)
	end,
	[23]=function(a)
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		return c:add(b)
	end,
	[36]=function(a)
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		return c:index(b)
	end,
	[20]=function(a)
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		return c:remove(b)
	end,
	[1]=function(a)
		return values:new()
	end
}

local dofunc = {
	initpos=0,
	finishpos=0
}

setmetatable(dofunc, {__index={
	new=function(a, b, c)
		return setmetatable({initpos=b, finishpos=c}, getmetatable(a))
	end,
	execasfunc=function(a, b, c)
		local e = c:pg(args)
		c:ps(args, b)
		local f = c.pos
		c:sp(a.initpos)
		while c.pos<=a.finishpos do
			if not c:interpreter(c:na(0)) then c:ap() break end
			c:ap()
		end
		local g = c:pg(retorno)
		c:pr(retorno)
		c:ps(args, e)
		c:sp(f)
		return g
	end,
	execasfor=function(a, b, c)
		local d = b:pg(cn)
		d:set(d:size(), c)
		local e = b.pos
		b:sp(a.initpos)
		while b.pos<=a.finishpos do
			if not b:interpreter(b:na(0)) then b:ap() b:sp(e) return nil end
			b:ap()
		end
		b:sp(e)
		return true
	end,
	justexec=function(a, b)
		local e = b.pos
		b:sp(a.initpos)
		while b.pos<=a.finishpos do
			if not b:interpreter(b:na(0)) then b:ap() b:sp(e) return nil end
			b:ap()
		end
		b:sp(e)
		return true
	end
}})

local dofuncB = { }

setmetatable(dofuncB, {__index={
	new=function(a, b, c)
		if c.func then c = c.func end
		return setmetatable({a=b, b=c}, getmetatable(a))
	end,
	execasfunc=function(a, b, c)
		return a.a:execasfunc(b, a.b)
	end,
	execasfor=function(a, b, c)
		return a.a:execasfor(a.b, c)
	end,
	justexec=function(a, b)
		return a.a:justexec(a.b)
	end
}})

local base = {
	43,
	['char']=0,
	['new']=1,
	['string']=1,
	['longstring']=2,
	['number']=3,
	['size']=3,
	['longnumber']=4,
	['define']=5,
	['set']=6,
	['get']=7,
	['use']=8,
	['function']=9,
	['if']=10,
	['elseif']=11,
	['else']=12,
	['while']=13,
	['for']=14,
	['do']=15,
	['od']=16,
	['return']=17,
	['break']=18,
	['and']=19,
	['not']=20,
	['remove']=20,
	['false']=21,
	['true']=22,
	['+']=23,
	['add']=23,
	['-']=24,
	['minus']=24,
	['/']=25,
	['divide']=25,
	['*']=26,
	['multiply']=26,
	['^']=27,
	['elevate']=27,
	['\\']=28,
	['reverse']=28,
	['|']=29,
	['absolute']=29,
	['=']=30,
	['equals']=30,
	['~']=31,
	['diferent']=31,
	['>']=32,
	['higher']=32,
	['<']=33,
	['lower']=33,
	['>=']=34,
	['ehigher']=34,
	['<=']=35,
	['elower']=35,
	['values']=36,
	['index']=36,
	['definekey']=37,
	['defineconst']=37,
	['exec']=38,
	['args']=39,
	['func']=40,
	['cn']=41,
	['concat']=42
}

local funcs = {
	function(a) -- char
		local b = a:na()
		a:ap()
		return string.char(b)
	end,
	function(a) -- string
		local c = ""
		local b = a:na()
		a:ap()
		for d=1, b do
			c=c .. string.char(a:na())
			a:ap()
		end
		return c
	end,
	function(a) -- longstring
		local c = ""
		a:ap()
		local b = (a:na(0)*256)+a:na()
		a:ap()
		for d=1, b do
			c=c .. string.char(a:na())
			a:ap()
		end
		return c
	end,
	function(a) -- number
		a:ap()
		return a:na(0)
	end,
	function(a) -- longnumber
		a:aq(2)
		return (a:na(-1)*256)+a:na(0)
	end,
	function(a) -- define
		a:aq(2)
		local b={'', "", "", 0, 0}
		b[21]=false
		b[22]=true
		b[36]=values:new()
		a:st(a:na(-1), b[a:na(0)])
		return a:sz()
	end,
	function(a) -- set
		a:aq(2)
		a:st(a:na(-1), a:interpreter(a:na(0)))
		return true
	end,
	function(a) -- get
		a:ap()
		return a:gt(a:na(0))
	end,
	function(a) -- use
		a:ap()
		local b = a:new()
		local aff = a:interpreter(a:na(0))
		b:open(aff)
		local c = true
		repeat
			c=b:execnext()
			collectgarbage("collect")
		until not c
		local c = b:pg(retorno)
		if c then
			if type(c)=="table" then
				if c.qntargs then
					return {qntargs=c.qntargs, func=dofuncB:new(c.func, b)}
				else
					return c
				end
			else
				return c
			end
		else
			return true
		end
	end,
	function(a) -- function
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		a:ps(funcao, {qntargs=b, func=c})
		return {qntargs=b, func=c}
	end,
	function(a) -- if
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		if b then
			c:justexec(a)
			a:ps(doif, false)
		else
			a:ps(doif, true)
		end
		return true
	end,
	function(a) -- elseif
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		if a:pg(doif) then
			if b then
				c:justexec(a)
				a:ps(doif, false)
			end
		end
		return true
	end,
	function(a) -- else
		a:ap()
		local b = a:interpreter(a:na(0))
		if a:pg(doif) then
			b:justexec(a)
			a:ps(doif, false)
		end
		return true
	end,
	function(a) -- while
		a:ap()
		local b = a.pos
		local c = a:interpreter(a:na(0))
		a:ap()
		local d = a:interpreter(a:na(0))
		local e = a.pos
		while c do
			if not d:justexec(a) then break end
			a:sp(b)
			c = a:interpreter(a:na(0))
		end
		a:sp(e)
		return true
	end,
	function(a) -- for
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		local c = a:interpreter(a:na(0))
		a:ap()
		local d = a:interpreter(a:na(0))
		a:ap()
		local e = a:interpreter(a:na(0))
		local f = a:pg(cn)
		f:add(b)
		for f=b, d, c do
			if not e:execasfor(a, f) then break end
		end
		f:remove(f:size())
		return true
	end,
	function(a) -- do
		a:ap()
		local b = a:interpreter(a:na(0))
		local c = dofunc:new(a.pos+1, b-2)
		a:sp(b-2)
		return c
	end,
	function(a) -- od
		return nil
	end,
	function(a) -- return
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ps(retorno, b)
		return b
	end,
	function(a) -- break
		return nil
	end,
	function(a) -- and
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b and a:interpreter(a:na(0))
	end,
	function(a) -- not
		a:ap()
		return not a:interpreter(a:na(0))
	end,
	function(a) -- false
		return false
	end,
	function(a) -- true
		return true
	end,
	function(a) -- +
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b+a:interpreter(a:na(0))
	end,
	function(a) -- -
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b-a:interpreter(a:na(0))
	end,
	function(a) -- /
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b/a:interpreter(a:na(0))
	end,
	function(a) -- *
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b*a:interpreter(a:na(0))
	end,
	function(a) -- ^
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b^a:interpreter(a:na(0))
	end,
	function(a) -- \
		a:ap()
		return a:interpreter(a:na(0))*(-1)
	end,
	function(a) -- |
		a:ap()
		return math.abs(a:interpreter(a:na(0)))
	end,
	function(a) -- =
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b==a:interpreter(a:na(0))
	end,
	function(a) -- ~
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b~=a:interpreter(a:na(0))
	end,
	function(a) -- >
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b>a:interpreter(a:na(0))
	end,
	function(a) -- <
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b<a:interpreter(a:na(0))
	end,
	function(a) -- >=
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b>=a:interpreter(a:na(0))
	end,
	function(a) -- <=
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b<=a:interpreter(a:na(0))
	end,
	function(a) -- values
		a:ap()
		local b = a:na(0)
		return valuesfuncs[b](a)
	end,
	function(a) -- definekey
		a:ap()
		local b = a:na(0)
		a:ap()
		local c = a:interpreter(a:na(0))
		local d = function(var)
			local e = values:new()
			for f=1, c.qntargs do
				a:ap()
				e:add(a:interpreter(a:na(0)))
			end
			return c.func:execasfunc(e, var)
		end
		a:af(b, d)
		return true
	end,
	function(a) -- exec
		a:ap()
		local b = a:interpreter(a:na(0))
		local e = values:new()
		for f=1, c.qntargs do
			a:ap()
			e:add(a:interpreter(a:na(0)))
		end
		return b.func:execasfunc(e, a)
	end,
	function(a) -- args
		if not a:pg(args) then
			return nil
		end
		a:ap()
		return a:pg(args):value(a:interpreter(a:na(0)))
	end,
	function(a) -- func
		return a:pg(funcao)
	end,
	function(a) -- cn
		return a:pg(cn)
	end,
	function(a) -- concat
		a:ap()
		local b = a:interpreter(a:na(0))
		a:ap()
		return b .. a:interpreter(a:na(0))
	end
}

if _G.SKLFuncs then
	for a, b in pairs(_G.SKLFuncs) do
		base[a]=base[1]
		base[1]=base[1]+1
		table.insert(funcs, b)
	end
end

if _G.SKLConstants then
	for a, b in pairs(_G.SKLConstants) do
		base[a]=b
	end
end

return {base, funcs}