--[[lit-meta
    name = "code-nuage/direct-mime"
    version = "0.0.1"
    homepage = "https://github.com/code-nuage/direct/blob/main/direct-mime.lua"
    description = "The mime types of the direct web microframework."
    tags = { "direct" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+             +--
--  direct-mime  --
--  @code-nuage  --
--+             +--

local M = {}
M.types = {
    html = "text/html",
    htm  = "text/html",
    css  = "text/css",
    js   = "application/javascript",
    json = "application/json",
    png  = "image/png",
    jpg  = "image/jpeg",
    jpeg = "image/jpeg",
    gif  = "image/gif",
    svg  = "image/svg+xml",
    txt  = "text/plain",
    md   = "text/markdown",
    pdf  = "application/pdf",
    ico  = "image/x-icon",
}

function M.guess(path)
    local ext = path:match("%.([^.]+)$")
    return M.types[ext] or "application/octet-stream"
end

return M