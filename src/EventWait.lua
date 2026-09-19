-- "Sleep until there's input, or until this many seconds pass."
--
-- love.event.wait() has no timeout and love.timer.sleep() can't be interrupted
-- by input, but SDL has exactly the call we want, so borrow it through
-- LuaJIT's FFI. With a NULL event pointer it only waits; the event stays queued
-- for love.event.pump()/poll() to deliver as usual.
--
-- EventWait.wait is nil where that isn't possible (no FFI, SDL not reachable);
-- the main loop then falls back to sleeping in short slices.
local EventWait = {}

local function _find_sdl_wait()
    local has_ffi, ffi = pcall(require, "ffi")
    if not has_ffi then
        return nil
    end

    ffi.cdef("int SDL_WaitEventTimeout(void *event, int timeout);")

    -- On Linux and macOS love's SDL is already in the process; on Windows it's a DLL.
    local candidates = {
        function() return ffi.C end,
        function() return ffi.load("SDL2") end,
    }
    for i=1, #candidates do
        local found, sdl_wait = pcall(function()
            return candidates[i]().SDL_WaitEventTimeout
        end)
        if found and sdl_wait then
            return sdl_wait
        end
    end
    return nil
end

local sdl_wait = _find_sdl_wait()

if sdl_wait then
    function EventWait.wait(seconds)
        sdl_wait(nil, math.max(math.floor(seconds * 1000), 1))
    end
end

return EventWait
