local input = {
    _handlers = {},
    _initialized = false,
    _states = {},
    _last_mouseX = -1,
    _last_mouseY = -1,
    enums = require("enums")
}

local backend

local function checkInit(self)
    if self._initialized then return end

    local os = jit.os

    if os == "OSX" then
        backend = require("macOS/backend")
        backend.init(self)
    elseif os == 'Windows' then
        error("Sorry, Windows is not supported yet! It is coming soon.")
    else
        error("Sorry, " .. os .. " is not supported yet. It will hopefully come soon.")
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

function input:stop()
    if not self._initialized then return end

    backend.stopLoop()
end

function input:getMousePosition()
    return self._last_mouseX, self._last_mouseY
end

function input:isDown(key)
    return self._states[key] ~= nil
end

return input
