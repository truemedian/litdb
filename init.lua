local input = {
    _handlers = {},
    _initialized = false,
    enums = require("enums")
}

local backend

local function checkInit(self)
    if self._initialized then return end

    if jit.os == "OSX" then
        backend = require("macOS/backend")
        backend.init(self)
    elseif jit.os == 'Windows' then
        error("Sorry, Windows is not supported yet! It is coming soon.")
    end

    self._initialized = true
end

function input:on(event, handler)
    checkInit(self)

    self._handlers[event] = self._handlers[event] or {}
    table.insert(self._handlers[event], handler)
end

function input:emit(event, ...)
    local handlers = self._handlers[event] or {}
    for _, handler in ipairs(handlers) do
        handler(...)
    end
end

function input:run()
    checkInit(self)
    backend.runLoop()
end

return input
