local format, gmatch = string.format, string.gmatch

local stmtFG = '\027[38;2;%d;%d;%sm%s\027[0m'
local stmtBG = '\027[48;2;%d;%d;%dm%s\027[0m'
local stmtFGBG = '\027[38;2;%d;%d;%d;48;2;%d;%d;%dm%s\027[0m'

local colorize = {}
colorize.__index = colorize

function colorize:__call(color, input)
    color = self.colors[color] or color
    local gen1 = gmatch(color, '[^;]+')
    local FG, BG = gen1(), gen1()
    FG = FG ~= '-' and FG
    if not FG and BG then
        gen1 = gmatch(BG, '[^, ]+')
        return format(stmtBG, gen1() or 0, gen1() or 0, gen1() or 0, input)
    end
    if FG and not BG then
        gen1 = gmatch(FG, '[^, ]+')
        return format(stmtFG, gen1() or 0, gen1() or 0, gen1() or 0, input)
    end
    gen1 = gmatch(FG, '[^, ]+')
    local gen2 = gmatch(BG, '[^, ]+')
    return format(stmtFGBG, gen1() or 0, gen1() or 0, gen1() or 0, gen2() or 0, gen2() or 0, gen2() or 0, input)
end

function colorize:setColor(name, value)
    self.colors[name] = value
end

local colors = {
    red = '255, 0, 0',
    green = '0, 255, 0',
    blue = '0, 0, 255'
}

return setmetatable({colors = colors}, colorize)