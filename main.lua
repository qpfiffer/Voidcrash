if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

local Clock = require("src/Clock")
local constants = require("src/Constants")
local DebugStats = require("src/DebugStats")
local GameState = require("src/GameState")
local Input = require("src/Input")
local MenuState = require("src/states/MenuState")
local EventWait = require("src/EventWait")
local Renderer = require("src/Renderer")

-- Game internals
local clock = nil
local game_state = nil
local renderer = nil

-- The window's contents are only guaranteed to survive while we're visible, so
-- the cached frame is put back up this often even if nothing changed.
local REPRESENT_INTERVAL = 1
-- Without EventWait (love built on plain Lua, no FFI) input has to be polled
-- for, and the polling interval is the input latency. So: poll fast right
-- after input, and ever more lazily the longer nobody has touched anything.
-- {seconds since last input, longest sleep}
local POLL_TIERS = {
    {2, 1/120},
    {30, constants.IDLE_SLICE},
    {math.huge, constants.DEEP_IDLE_SLICE},
}

-- Yeah whatever nerd:
math.randomseed(os.time())

-- VOIDCRASH_STRICT=1 turns accidental globals into errors instead of silent bugs.
if os.getenv("VOIDCRASH_STRICT") == "1" then
    local warned = {}
    setmetatable(_G, {
        __newindex = function(_, name)
            error("write to undeclared global '" .. tostring(name) .. "'", 2)
        end,
        __index = function(_, name)
            if not warned[name] then
                warned[name] = true
                print("read of undeclared global '" .. tostring(name) .. "'\n" .. debug.traceback("", 2))
            end
            return nil
        end,
    })
end

function love.load(arg)
    -- Window setup lives in conf.lua.
    local initial_scale = 1.5
    local initial_window_width = love.graphics.getWidth()
    local initial_window_height = love.graphics.getHeight()

    love.mouse.setVisible(false)

    clock = Clock.new({
        step = 1 / constants.SIM_HZ,
        blink_period = constants.BLINK_PERIOD,
        -- We sleep for up to REPRESENT_INTERVAL on purpose; only longer gaps are stalls.
        max_catchup = REPRESENT_INTERVAL * 2,
    })

    local initial_state = MenuState:init()
    game_state = GameState:init(initial_state, clock)
    renderer = Renderer:init(initial_scale, initial_window_width, initial_window_height)
end

function love.keypressed(key)
    Input.key_pressed(key)
    if key == "f3" then
        return DebugStats.toggle()
    end
    game_state:key_pressed(key)
    game_state:invalidate()
end

function love.keyreleased(key)
    Input.key_released(key)
end

function love.focus(focused)
    if not focused then
        Input.clear()
    end
    game_state:invalidate()
end

function love.visible(visible)
    game_state:invalidate()
end

function love.resize()
    game_state:invalidate()
end

-- The stock love.run updates and redraws flat out. Nearly everything in this
-- game is static between key presses, so instead: advance the clock, redraw
-- only if something asked for it, then block until there's input or the clock
-- next has work.
function love.run()
    love.load(love.arg.parseGameArguments(arg), arg)

    -- Don't count the time love.load took.
    love.timer.step()

    local last_input_at = love.timer.getTime()
    local last_present_at = 0
    local last_sim_draw_at = 0
    local sim_dirty = false
    local last_blink = nil

    -- Returns an exit code if the event means we're done.
    local function dispatch(name, a, b, c, d, e, f)
        if name == "quit" then
            if not love.quit or not love.quit() then
                return a or 0
            end
        end
        if name == "keypressed" or name == "keyreleased" then
            last_input_at = love.timer.getTime()
        end
        love.handlers[name](a, b, c, d, e, f)
        return nil
    end

    return function()
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            local exit_code = dispatch(name, a, b, c, d, e, f)
            if exit_code then
                return exit_code
            end
        end

        local dt = love.timer.step()
        local now = love.timer.getTime()
        DebugStats.tick()

        local steps, fires = clock.stats.steps, clock.stats.fires
        local ui_fires = clock.ui.fired
        game_state:update(dt)
        DebugStats.count("sim", clock.stats.steps - steps)
        DebugStats.count("timers", clock.stats.fires - fires)

        -- What needs a redraw: anything that asked, any ui timer (they only run
        -- for the screen being shown), a blink edge, and the world having moved
        -- (rate limited; nobody needs 60 redraws a second of a crawling frame).
        if clock.ui.fired ~= ui_fires then
            game_state:invalidate()
        end
        local blink = clock.blink_needed and clock:blink_on()
        if blink ~= last_blink then
            last_blink = blink
            game_state:invalidate()
        end
        if clock.stats.steps ~= steps then
            sim_dirty = true
        end
        if sim_dirty and now - last_sim_draw_at >= 1 / constants.SIM_REDRAW_HZ then
            sim_dirty = false
            last_sim_draw_at = now
            game_state:invalidate()
        end

        local can_draw = love.graphics.isActive() and love.window.isVisible()
        local dirty = game_state:consume_dirty() or DebugStats.consume_redraw()
        if can_draw and (dirty or now - last_present_at >= REPRESENT_INTERVAL) then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())
            if dirty then
                DebugStats.count("draw")
                renderer:render(game_state)
            else
                renderer:present_cached()
            end
            DebugStats.count("present")
            love.graphics.present()
            last_present_at = now
        end

        -- Sleep until something is due. Presenting may have blocked on vsync, so
        -- measure from when the clock was advanced, not from now.
        local wake = math.min(
            clock:next_wake() or math.huge,
            DebugStats.next_wake(now) or math.huge,
            sim_dirty and (last_sim_draw_at + 1 / constants.SIM_REDRAW_HZ - now) or math.huge,
            last_present_at + REPRESENT_INTERVAL - now)
        if not EventWait.wait then
            -- Polling fallback: input waits for us, so never sleep long.
            for i=1, #POLL_TIERS do
                if now - last_input_at < POLL_TIERS[i][1] then
                    wake = math.min(wake, POLL_TIERS[i][2])
                    break
                end
            end
        end

        -- Aim a hair past the deadline: waking just short of it would mean
        -- spinning until it arrives. And always yield, like the stock loop does.
        local sleep_for = math.max(wake - (love.timer.getTime() - now) + 0.0005, 0.001)
        if EventWait.wait then
            EventWait.wait(sleep_for) -- Returns early if there's input.
        else
            love.timer.sleep(sleep_for)
        end
    end
end
