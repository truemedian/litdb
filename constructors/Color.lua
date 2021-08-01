local Color = {}
Color.__index = Color
Color.__metatable = false
Color.Class = "Color"

local _scanparam = require("../util/ScanParam")
local _typeof = require("../util/TypeOf")
local _log = require("../util/Log")

function Color.new(R, G, B)
    _scanparam({"R", R}, {"number"}, true, true)
    _scanparam({"G", G}, {"number"}, true, true)
    _scanparam({"B", B}, {"number"}, true, true)

    assert(R >= 0 and R < 256, "R is Out Of Bounds!")
    assert(G >= 0 and G < 256, "G is Out Of Bounds!")
    assert(B >= 0 and B < 256, "B is Out Of Bounds!")

    local clr = {}
    clr.R = R
    clr.G = G
    clr.B = B

    return setmetatable(clr, Color)
end

function Color:ToHex()
    return string.format("0x%02X%02X%02X", self.R, self.G, self.B)
end

Color.__call = function(_, ...) return Color.new(...) end

return setmetatable(Color, Color)