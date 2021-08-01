-- Special thanks to SinisterRectus
local Settings = require("../Settings")
local fs = require("fs")

local RED     = 31
local GREEN   = 32

local config = {
	{'[LOG]', GREEN},
    {'[ERROR]', RED},
}

do
	local bold = 1
	for _, v in ipairs(config) do
		v[2] = string.format('\27[%i;%im%s\27[0m', bold, v[2], v[1])
	end
end

return function (level, msg, ...)
    if not Settings.LOGGER.ACTIVATED then return end

    local tag = config[level]
    if not tag then return end

    msg = string.format(msg, ...)
    if Settings.LOGGER.WRITE_FILE == true then
        local file = fs.openSync(Settings.LOGGER.FILE_PATH.."dh.log", "a+")
        fs.writeSync(file, -1, string.format("%s > %s\n", tag[1], msg))
        fs.close(file)
    end

    print(string.format("%s > %s", tag[2], msg))
end