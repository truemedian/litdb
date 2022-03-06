--[[lit-meta
	name = "TohruMKDM/color-print"
    version = "1.0.2"
    description = "Write text in terminal with colors"
    tags = { "colors", "print", "color" }
    license = "MIT"
    author = { name = "Tohru~ (トール)", email = "admin@ikaros.pw" }
    homepage = "https://github.com/TohruMKDM/color-print"
]]

local sub, format = string.sub, string.format
local match, gmatch = string.match, string.gmatch
local concat = table.concat

local stmtFG = '\027[38;2;%s;%s;%sm%s\027[0m'
local stmtBG = '\027[48;2;%s;%s;%sm%s\027[0m'
local stmtFGBG = '\027[38;2;%s;%s;%s;48;2;%s;%s;%sm%s\027[0m'

return function(...)
    local args = {...}
    for i = 1, #args do
        local arg = tostring(args[i])
        local colors, str = match(arg, '(%b[])(%b())')
        if not colors then
            args[i] = arg
        else
            local gen1, gen2
            colors = sub(colors, 2, -2)
            gen1 = gmatch(colors, '[^;]+')
            local fg, bg = gen1(), gen1()
            fg = fg ~= '-' and fg
            if not fg and bg then
                gen1 = gmatch(bg, '[^, ]+')
                args[i] = format(stmtBG, gen1() or 0, gen1() or 0, gen1() or 0, sub(str, 2, -2))
            elseif fg and not bg then
                gen1 = gmatch(fg, '[^, ]+')
                args[i] = format(stmtFG, gen1() or 0, gen1() or 0, gen1() or 0, sub(str, 2, -2))
            else
                gen1, gen2 = gmatch(fg, '[^, ]+'), gmatch(bg, '[^, ]+')
                args[1] = format(stmtFGBG, gen1() or 0, gen1() or 0, gen1() or 0, gen2() or 0, gen2() or 0, gen2() or 0, sub(str, 2, -2))
            end
        end
    end
    return print(concat(args, '\t'))
end
