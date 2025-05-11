local ffi = require("ffi")
local C = ffi.C

local bit = require("bit")
local bor = bit.bor
local lshift = bit.lshift

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

    typedef uint16_t UniChar;
    typedef UniChar* UniCharPtr;
    typedef uint32_t UniCharCount;

    typedef struct __TISInputSource * TISInputSourceRef;
    typedef struct __CFString * CFStringRef;

    TISInputSourceRef TISCopyCurrentKeyboardLayoutInputSource(void);
    const void* TISGetInputSourceProperty(TISInputSourceRef inputSource, CFStringRef propertyKey);

    CFStringRef CFStringCreateWithCharacters(void* alloc, const UniChar* chars, UniCharCount numChars);
    bool CFStringGetCString(CFStringRef theString, char* buffer, long bufferSize, int encoding);

    enum {
        kCFStringEncodingUTF8 = 0x08000100
    };

    static const int kTISPropertyUnicodeKeyLayoutData = 0x75636872; // 'uchr' in ASCII as hex
]]

local core = ffi.load("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")

local EVENT_TYPE = require("macOS/eventTypes")

local function init(self)
    local states = {}
    local function event(proxy, type, ref, userData)
        local keycode = tonumber(ffi.cast("uintptr_t", C.CGEventGetIntegerValueField(ref, 9))) -- 9 = kCGKeyboardEventKeycode
        -- if not keycode then return end

        if type == EVENT_TYPE.KEY_DOWN then
            if not states[keycode] then
                ---@diagnostic disable-next-line: need-check-nil
                states[keycode] = true

                self:emit("key_press", keycode)
            end
        elseif type == EVENT_TYPE.KEY_UP then
            if states[keycode] then
                ---@diagnostic disable-next-line: need-check-nil
                states[keycode] = nil

                self:emit("key_release", keycode)
            end
        end

        return ref -- return unmodified event
    end

    local c_callback = ffi.cast("CGEventTapCallBack", event)

    -- we are interested in key down & key up
    -- TODO: also implement mouse events
    local event_mask = bor(
        lshift(1, EVENT_TYPE.KEY_DOWN),
        lshift(1, EVENT_TYPE.KEY_UP)
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
    -- just enables listening to key events
    core.CGEventTapEnable(event_tap, true)

    -- attaching our "tap" to the run loop
    local source = core.CFMachPortCreateRunLoopSource(nil, event_tap, nil)
    core.CFRunLoopAddSource(core.CFRunLoopGetCurrent(), source, C.kCFRunLoopCommonModes)
end

return {
    init = init,
    runLoop = core.CFRunLoopRun
}
