local ffi = require("ffi")
local C = ffi.C

local uv = require("uv")

local bit = require("bit")
local bor = bit.bor
local lshift = bit.lshift

--[[
https://developer.apple.com/documentation/coregraphics?language=objc
https://developer.apple.com/documentation/coregraphics/quartz-event-services?language=objc
https://developer.apple.com/documentation/corefoundation?language=objc
https://developer.apple.com/documentation/corefoundation/cfrunloop?language=objc
https://developer.apple.com/documentation/corefoundation/cfstring?language=objc
]]

ffi.cdef [[
    typedef void* CFRunLoopRef;
    typedef void* CGEventRef;
    typedef void* CGEventTapProxy;
    typedef unsigned int CGEventType;
    typedef CGEventRef (*CGEventTapCallBack)(
        CGEventTapProxy proxy,
        CGEventType type,
        CGEventRef event,
        void *userInfo
    );

    CFRunLoopRef CFRunLoopGetCurrent(void);
    void CFRunLoopRun(void);
    void CFRunLoopStop(CFRunLoopRef rl);

    double CFRunLoopRunInMode(const void* mode, double seconds, bool returnAfterSourceHandled);

    void* CGEventTapCreate(
        int tap,
        int place,
        int options,
        uint64_t eventsOfInterest,
        CGEventTapCallBack callback,
        void* userInfo
    );
    void* CFMachPortCreateRunLoopSource(void*, void*, void*);
    void CFRunLoopAddSource(CFRunLoopRef rl, void* source, const void* mode);
    extern const void* kCFRunLoopCommonModes;

    int CGEventTapEnable(void* tap, bool enable);

    long long CGEventGetIntegerValueField(CGEventRef event, int field);

    // used for mouse location
    typedef struct {
        double x;
        double y;
    } CGPoint;

    CGPoint CGEventGetLocation(CGEventRef event);
    // double CGEventGetDoubleValueField(CGEventRef event, int field); // used for ultra precise mouse readings

    extern const void* kCFRunLoopDefaultMode;
]]

local core = ffi.load("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")

local EVENT_TYPE = require("macOS/eventTypes")
local MOUSEBUTTON_MAP = {
    [0] = "left",
    [1] = "right",
    [2] = "middle"
}

local function init(self)
    local function event(proxy, type, ref, userData)
        local keycode = tonumber(ffi.cast("uintptr_t", C.CGEventGetIntegerValueField(ref, 9))) -- 9 = kCGKeyboardEventKeycode
        -- if not keycode then return end

        if type == EVENT_TYPE.KEY_DOWN then
            if not self._states[keycode] then
                ---@diagnostic disable-next-line: need-check-nil
                self._states[keycode] = true

                self:emit("key_press", keycode)
            end
        elseif type == EVENT_TYPE.KEY_UP then
            if self._states[keycode] then
                ---@diagnostic disable-next-line: need-check-nil
                self._states[keycode] = nil

                self:emit("key_release", keycode)
            end
        end

        local mouse_button = tonumber(ffi.cast("uintptr_t", C.CGEventGetIntegerValueField(ref, 23))) -- kCGMouseEventButtonNumber
        local location = core.CGEventGetLocation(ref)
        local x = location.x
        local y = location.y

        if x == nil or y == nil then return ref end

        self._last_mouseX = x
        self._last_mouseY = y

        local side = MOUSEBUTTON_MAP[mouse_button] or "unknown"

        if type == EVENT_TYPE.MOUSE_MOVED then
            self:emit("mouse_move", x, y)
        elseif type == EVENT_TYPE.MOUSE_DOWN then
            self._mouseStates[side] = true
            self:emit("mouse_down", side, x, y)
        elseif type == EVENT_TYPE.MOUSE_UP then
            self._mouseStates[side] = nil
            self:emit("mouse_up", side, x, y)
        elseif type == EVENT_TYPE.MOUSE_DRAGGED then
            self:emit("mouse_drag", side, x, y)
        elseif type == EVENT_TYPE.MOUSE_WHEEL then
            -- ultra precise mouse scroll readings
            -- local scroll_x = core.CGEventGetDoubleValueField(ref, 93)         -- kCGScrollWheelEventDeltaAxis1
            -- local scroll_y = core.CGEventGetDoubleValueField(ref, 94)         -- kCGScrollWheelEventDeltaAxis2

            local scroll_x = tonumber(C.CGEventGetIntegerValueField(ref, 93)) -- horizontal
            local scroll_y = tonumber(C.CGEventGetIntegerValueField(ref, 94)) -- vertical
            local is_smooth = C.CGEventGetIntegerValueField(ref, 96) == 1     -- smooth scroll

            if scroll_x == 0 and scroll_y == 0 then return ref end

            self:emit("mouse_scroll", scroll_x, scroll_y, is_smooth)
        end

        return ref -- return unmodified event
    end

    local c_callback = ffi.cast("CGEventTapCallBack", event)

    local event_mask = bor(
        lshift(1, EVENT_TYPE.KEY_DOWN),
        lshift(1, EVENT_TYPE.KEY_UP),
        lshift(1, EVENT_TYPE.MOUSE_DOWN),
        lshift(1, EVENT_TYPE.MOUSE_UP),
        lshift(1, EVENT_TYPE.MOUSE_MOVED),
        lshift(1, EVENT_TYPE.MOUSE_DRAGGED),
        lshift(1, EVENT_TYPE.MOUSE_WHEEL)
    )

    local event_tap = core.CGEventTapCreate(
        0, -- kCGHIDEventTap
        0, -- kCGHeadInsertEventTap
        0, -- kCGEventTapOptionDefault
        event_mask,
        c_callback,
        nil
    )

    if event_tap == nil then
        error(
            "Failed to create the event tap. Ensure that Luvit (or parent process, e.g. VSCode if youre running Luvit from the integrated terminal) has the Accessibility permission in System Settings.")
    end

    -- the name is slightly deceptive, it doesnt listen for literal "taps" on desktop
    -- just enables listening to key events and mouse, etc
    core.CGEventTapEnable(event_tap, true)

    -- attaching our "tap" to the run loop
    local source = core.CFMachPortCreateRunLoopSource(nil, event_tap, nil)
    core.CFRunLoopAddSource(core.CFRunLoopGetCurrent(), source, C.kCFRunLoopCommonModes)
end

local timer
local function runLoop()
    if timer then return end

    local interval_ms = 10
    timer = uv.new_timer()

    timer:start(0, interval_ms, function()
        core.CFRunLoopRunInMode(C.kCFRunLoopDefaultMode, interval_ms / 1000, false)
    end)
end

local function stopLoop()
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
end

return {
    init = init,
    runLoop = runLoop,
    stopLoop = stopLoop
}
