local timer = require('timer')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
process.stdout:write('hello world\n')
timer.setTimeout(1000, function() end)
process:on('exit', function()
  p('on exit')
end)
process:exit(0)
