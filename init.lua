local prettyPrint = require('pretty-print')
prettyPrint.useColors = true
prettyPrint.loadColors(prettyPrint.theme[256])

exports.output = nil
local a={{n='warn',c='boolean'},{n='success',c='quotes'},{n="info",c='table'},{n='error',c='err'}}

for i, x in ipairs(a) do
    exports[x.n] = function(...)
        local i = debug.getinfo(2, "Sl")
        local li = i.short_src .. ":" .. i.currentline
        local nu = x.n
        local cc = x.c
        local color = prettyPrint.color(cc)
        local normal = prettyPrint.color('property')
        local ms = ...
        prettyPrint.print(string.format('%s[%s%s] %s%s',
            color, nu, ' at '..li, normal, ms
        ))
        if exports.output then
            local out = io.open(exports.output, 'a')
            local put = string.format('(%s)[%s%s] %s', os.date('%H:%M:%S'),nu, ' at '..li, ms)
            out:write(put..'\n')
            out:close()
        end
    end
end
