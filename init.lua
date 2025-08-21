require("./hexConstants")
local a = require("./lexer")
local b = require("./check")
local c = require("./keys")[1]
local d = require("./interpreter")

return {
	compileToTable=function(e)
		if not e then error("Argument missing in compileToTable") end
		if not type(e)=='string' then error("First argument: String expected, got " .. type(e)) end
		return b(a(e), c)
	end,
	compileToArchive=function(e, f)
		if not e then error("First argument missing in compileToArchive") end
		if not f then error("Second argument missing in compileToArchive") end
		if not type(e)=='string' then error("First argument: String expected, got " .. type(e)) end
		if not type(f)=='userdata' then error("Second argument: Userdata expected, got " .. type(f)) end
		local g, h = b(a(e), c)
		if g then
			f:setvbuf("no")
			for i=1, #h do
				if type(h[i])=='number' then f:write(string.char(h[i])) else f:write(h[i]) end
			end
			f:close()
		else
			return g, h
		end
	end,
	runFromTable=function(e, f)
		if not e then error("Argument missing in runFromTable")
		if f and not type(f)=='function' then error("Second argument expect function in runFromTable") end
		if not type(e)=='table' then error("First argument: Table expected, got " .. type(e)) end
		local g = d(f)
		g.archive=setmetatable({pos=0, t=e}, {__index={
			read=function(i, j)
				i.pos=i.pos+1
				return i.t[i.pos]
			end,
			seek=function(i, j, k)
				i.pos=k
			end
		})
		local h=true
		repeat
			h=g:execnext()
		until not h
		return g:pg(0)
	end,
	runFromArchive=function(e, f)
		if not e then error("Argument missing in runFromArchive") end
		if f and not type(f)=='function' then error("Second argument expect function in runFromArchive") end
		if not type(e)=='userdata' then error("First argument: Userdata expected, got " .. type(e)) end
		local g = d(f)
		g.archive=e
		local h=true
		repeat
			h=g:execnext()
		until not h
		return g:pg(0)
	end
}