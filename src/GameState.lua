local GameState = {}
GameState.__index = GameState

local constants = require("src/Constants")
local PlayerInfo = require("src/PlayerInfo")

function GameState:init(initial_state, clock)
    local this = {
        current_state = nil,
        active_states = {},

        clock = clock, -- All time lives here; pausing freezes clock.sim.
        player_info = PlayerInfo:init(clock),
        menu_open = false, -- Show the menu
        game_started = false, -- Whether we've reached the game screens, map, lattice, etc.
        dirty = true, -- Whether the screen needs redrawing.
    }
    setmetatable(this, self)

    -- The world only moves on sim steps, so pause and catch-up are the clock's problem.
    -- While nothing in the world is doing anything, no steps run at all.
    clock:on_step(function(step) this.player_info:step(this, step) end)
    clock:set_sim_active(function() return this.player_info:is_sim_active() end)

    this:_set_current_state(initial_state)

    return this
end

function GameState:_set_current_state(new_state)
    if not new_state or new_state == self.current_state then
        return
    end

    if self.current_state then
        self.current_state:_exit(self)
    end
    self.current_state = new_state
    self.clock:set_blink_needed(new_state:uses_blink())
    self:invalidate()
    -- Must stay last: entering a screen may immediately switch to another one.
    new_state:_enter(self)
end

function GameState:key_pressed(key)
    if key == "escape" then
        -- TODO: push_state menu
        love.event.quit()
    end

    -- Any input restarts the blink in its "on" phase, on every screen.
    self.clock:reset_blink()

    if self:get_game_started() then
        local tab = self.active_states[tonumber(key)]
        if tab then
            -- The digit belongs to the tab bar, not to the tab it selects.
            return self:_set_current_state(tab)
        end
    end

    return self.current_state:key_pressed(self, key)
end

function GameState:add_active_state(state)
    table.insert(self.active_states, state)
end

function GameState:switch_active_state(idx)
    self:_set_current_state(self.active_states[idx])
end

function GameState:push_state(new_state, is_active)
    if is_active then
        table.insert(self.active_states, new_state)
    end
    self:_set_current_state(new_state)
end

function GameState:pop_state()
    -- TBD
end

function GameState:get_current_state()
    return self.current_state
end

function GameState:set_player_info(pi)
    self.player_info = pi
end

function GameState:get_player_info()
    return self.player_info
end

function GameState:set_paused(new)
    self.clock:set_paused(new)
    self:invalidate()
end

-- Ask for a redraw. Nothing is drawn unless somebody does.
function GameState:invalidate()
    self.dirty = true
end

function GameState:consume_dirty()
    local was_dirty = self.dirty
    self.dirty = false
    return was_dirty
end

function GameState:get_paused()
    return self.clock:is_paused()
end

function GameState:set_menu_open(new)
    self.menu_open = new
end

function GameState:get_menu_open()
    return self.menu_open
end

function GameState:set_game_started(new)
    self.game_started = new
end

function GameState:get_game_started()
    return self.game_started
end

function GameState:_render_tabs(renderer)
    local accum = 1
    renderer:set_color("white")
    for i in pairs(self.active_states) do
        local is_active = false
        if self.active_states[i] == self.current_state then
            is_active = true
        end

        if i ~= 1 then
            accum = accum + renderer:draw_string("| ", constants.MAP_Y_MAX + 2, accum)
        end
        if is_active then
            renderer:set_color("red")
        end
        accum = accum + renderer:draw_string(self.active_states[i]:get_name() .. " ", constants.MAP_Y_MAX + 2, accum)
        renderer:set_color("white")
    end

    if self:get_paused() then
        local middle_x = constants.MAP_X_MAX/2 - ((string.len("PAUSED") + 4) / 2)
        renderer:render_window_with_text(middle_x, constants.MAP_Y_MAX, "P")
    end
end

function GameState:render_current_state(renderer)
    self.current_state:render(renderer, self)
    self:_render_tabs(renderer)
end

function GameState:update(dt)
    self.clock:advance(dt)
end

return GameState
