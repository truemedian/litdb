local loader = require'./init.lua'
local example = loader.file'./example.lua'
example:handle()
example.onExit = function()
    print('Example.lua exited :(')
end

require'timer'.setTimeout(5000, function()
    example:terminate()
end)