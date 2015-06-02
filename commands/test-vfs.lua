local fs = require('vfs').chroot(args[2])

p(fs)
p("", fs.stat(""))
p("main.lua", fs.stat("main.lua"))
p("lib", fs.stat("lib"))
p("lib/codec.lua", fs.stat("lib/codec.lua"))
for entry in fs.scandir("") do
  p(entry)
end

for entry in fs.scandir("deps") do
  p(entry)
end

p(fs.readFile("main.lua"))
