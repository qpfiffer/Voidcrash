if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

local Clock = require("src/Clock")
local constants = require("src/Constants")
local DebugStats = require("src/DebugStats")
local GameState = require("src/GameState")
local MenuState = require("src/states/MenuState")
local Renderer = require("src/Renderer")

-- Game internals
local clock = nil
local game_state = nil
local renderer = nil

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

    clock = Clock.new({step = 1 / constants.SIM_HZ, blink_period = constants.BLINK_PERIOD})

    local initial_state = MenuState:init()
    game_state = GameState:init(initial_state, clock)
    renderer = Renderer:init(initial_scale, initial_window_width, initial_window_height)
end

function love.keypressed(key)
    if key == "f3" then
        return DebugStats.toggle()
    end
    game_state:key_pressed(key)
end

function love.update(dt)
    DebugStats.tick()
    DebugStats.count("update")

    local steps, fires = clock.stats.steps, clock.stats.fires
    game_state:update(dt)
    DebugStats.count("sim", clock.stats.steps - steps)
    DebugStats.count("timers", clock.stats.fires - fires)
end

function love.draw()
    DebugStats.count("draw")
    renderer:render(game_state)
end
