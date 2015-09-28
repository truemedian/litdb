
local sub, find = string.sub, string.find

module.exports.split = function(str, sep, nmax)
    if sep == nil then
        sep = '%s+'
    end
    local r = { }
    if #str <= 0 then
        return r
    end
    local plain = false
    nmax = nmax or -1
    local nf = 1
    local ns = 1
    local nfr, nl = find(str, sep, ns, plain)
    while nfr and nmax ~= 0 do
        r[nf] = sub(str, ns, nfr - 1)
        nf = nf + 1
        ns = nl + 1
        nmax = nmax - 1
        nfr, nl = find(str, sep, ns, plain)
    end
    r[nf] = sub(str, ns)
    return r
end
