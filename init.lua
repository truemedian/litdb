--[[
    MIT License

    Copyright (c) 2019 The Horas Compiler and Interpreter Team

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local test = {}

test.is_cli = true

-- Lambda: red text
local function red(s) return '\27[31m' .. s .. '\27[0m' end

-- Lambda: green text
local function green(s) return '\27[32m' .. s .. '\27[0m' end

function test.new(case, callback)
    if test.is_cli then
        return xpcall(function()
            callback()
            print(green('ok\t') .. case)
        end, function(message)
            print(red('error\t') .. case)
            print('\t' .. message)
            os.exit(1)
        end)
    else
        return xpcall(function()
            callback()
            return true, nil
        end, function(message)
            return false, message
        end)
    end
end

return setmetatable(test, {
    __call = function(_, case, callback)
        return test.new(case, callback)
    end
})
