local module = {}

module.checkText = function(str, pattern)
    if string.find(str, pattern) then
        return true
    else
        return false
    end
end

module.shift = function(tab)
    local newtab = tab[1]
    table.remove(tab, 1)

    return newtab
end

module.splitText = function(str, separator)
    local tab = {}

    if not separator then
        separator = " "
    end

    for v in string.gmatch(str, "[^"..separator.."%s]+") do
        table.insert(tab, v)
    end
    return tab
end

module.randomText = function(...)
    local tab = {...}

    return tab[math.random(1, #tab)]
end

return module