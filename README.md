# Luvit-read-directory-recursive

E.g
```
local readdirRecursive = require('luvit-read-directory-recursive').readdirRecursive

readdirRecursive(readdir('/etc', function(k, v) print(table.concat(v, '\n')) end)
```


