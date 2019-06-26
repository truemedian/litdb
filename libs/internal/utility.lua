local utility = {}

function utility.split(str)
	local splited = {}

	for i in string.gmatch(str, "%S+") do
		table.insert(splited, i)
	end

	return splited
end

function utility.reverse(tabl)
	for i, v in pairs(tabl) do
		tabl[v] = i
	end

	return tabl
end

function utility.protectedReverse(tabl)
	if tabl then
		return utility.reverse(tabl)
	else
		return nil
	end
end

return utility