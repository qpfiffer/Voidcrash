-- Base for everything GameState can show. Screens are views: they draw, take
-- input, and own a scope of ui timers that only run while they're on screen.
--
--   local MyState = Screen.extend()
--
-- Hooks (all optional):
--   on_start(game_state)  first time the screen is shown; create timers here
--   on_enter(game_state)  every time it becomes the current screen
--   on_exit(game_state)   every time it stops being the current screen
local Screen = {}
Screen.__index = Screen

function Screen.extend()
    local class = {}
    class.__index = class
    return setmetatable(class, Screen)
end

function Screen:get_name()
    return nil
end

function Screen:key_pressed(game_state, key)
end

function Screen:render(renderer, game_state)
end

function Screen:on_start(game_state)
end

function Screen:on_enter(game_state)
end

function Screen:on_exit(game_state)
end

-- Whether a blinking cursor is visible (decides if blink edges need redraws).
function Screen:uses_blink()
    return false
end

-- Called by GameState only.
function Screen:_enter(game_state)
    if not self.timers then
        self.timers = game_state.clock.ui:scope()
        self:on_start(game_state)
    end
    self.timers:resume()
    self:on_enter(game_state)
end

function Screen:_exit(game_state)
    self:on_exit(game_state)
    if self.timers then
        self.timers:suspend()
    end
end

return Screen
