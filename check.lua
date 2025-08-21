local function check(a, b)
	local f = b
	local e = {}
	local h = {}
	local c=1
	local nv=0
	while true do
		local d=type(a[c])
		local k=1
		if d=='string' then
			if not f[a[c]] then return false, "Key not found: " .. a[c] .. "\nnumber: " .. c end
			table.insert(e, f[a[c]])
			if a[c]=='define' then
				if type(a[c+1])=='string' and (not f[a[c+1]]) and type(a[c+2])=='string' then
					if (f[a[c+2]]>=5) and (f[a[c+2]]~=21 and f[a[c+2]]~=22 and f[a[c+2]]~=36) then return false, "define error: " .. a[c] .. " " .. a[c+1] .. " " .. a[c+2] .. "\nnumber: " .. c .. " and " .. c+1 .. " and " .. c+2 end
					f[a[c+1]]=nv
					table.insert(e, nv)
					table.insert(e, f[a[c+2]])
					nv=nv+1
					k=k+2
				else
					return false, "define error: " .. a[c] .. " " .. a[c+1] .. "\nnumber: " .. c .. " and " .. c+1
				end
			elseif a[c]=='definekey' then
				k=k+1
				table.insert(e, f[1])
				f[a[c+1]]=f[1]
				f[1]=f[1]+1
			elseif a[c]=='do' then
				table.insert(h, 1, #e+1)
			elseif a[c]=='od' then
				if not h[1] then return false, "incorrect close: " .. a[c] .. "\nnumber: " .. c end
				local q, r = math.modf((#e+(#h*3))/256)
				table.insert(e, h[1], r*256)
				table.insert(e, h[1], q)
				table.insert(e, h[1], 4)
				table.remove(h, 1)
				table.remove(e, #e)
			end
			
		elseif d=='number' then
			if a[c]>=256 then
				table.insert(e, 4)
				local q, r = math.modf(a[c]/256)
				table.insert(e, q)
				table.insert(e, r*256)
			else
				table.insert(e, 3)
				table.insert(e, a[c])
			end
		elseif d=='table' then
			if #a[c][1]==1 then
				table.insert(e, 0)
				table.insert(e, a[c][1])
			elseif #a[c][1]>255 then
				local q, r = math.modf(#a[c][1]/256)
				table.insert(e, 2)
				table.insert(e, q)
				table.insert(e, r*256)
				for g=1, #a[c][1] do
					table.insert(e, string.sub(a[c][1], g, g))
				end
			else
				table.insert(e, 1)
				table.insert(e, #a[c][1])
				for g=1, #a[c][1] do
					table.insert(e, string.sub(a[c][1], g, g))
				end
			end
			
		end
		if c>=#a then break end
		c=c+k
	end
	if #h~=0 then return false, "do not closed" end
	return true, e
end

return check