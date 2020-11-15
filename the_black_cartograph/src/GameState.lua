local GameState = {}
GameState.__index = GameState

local constants = require("src/Constants")
local PlayerInfo = require("src/PlayerInfo")

function GameState:init(initial_state)
    local this = {
        current_state = initial_state,
        active_states = {},

        player_info = PlayerInfo:init(),
        paused = false, -- Whether or not ticks advance game objects
        menu_open = false, -- Show the menu
        game_started = false, -- Whether we've reached the game screens, map, lattice, etc.
    }
    setmetatable(this, self)

    return this
end

function GameState:key_pressed(key)
    -- if key == "escape" then
    --     -- TODO: push_state menu
    --     love.event.quit()
    -- end
    if self:get_game_started() then
        if key == "1" then
            self.current_state = self.active_states[1]
        elseif key == "2" then
            self.current_state = self.active_states[2]
        elseif key == "3" then
            self.current_state = self.active_states[3]
        elseif key == "4" then
            self.current_state = self.active_states[4]
        end
    end

    return self.current_state:key_pressed(self, key)
end

function GameState:add_active_state(state)
    table.insert(self.active_states, state)
end

function GameState:switch_active_state(idx)
    self.current_state = self.active_states[idx]
end

function GameState:push_state(new_state, is_active)
    self.current_state = new_state
    if is_active then
        table.insert(self.active_states, new_state)
    end
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
    self.paused = new
end

function GameState:get_paused()
    return self.paused
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

function GameState:_render_paused(renderer)
    if not self.paused then
        return
    end

    local middle_x = constants.MAP_X_MAX/2 - ((string.len("PAUSED") + 4) / 2)
    renderer:render_window_with_text(constants.MAP_X_MAX/2, constants.MAP_Y_MAX, "PAUSED")
end

function GameState:render_current_state(renderer)
    self.current_state:render(renderer, self)
    self:_render_paused(renderer)
end

function GameState:update_current_state(dt)
    self.player_info.cur_tick = self.player_info.cur_tick + (dt / constants.TICK_SLOW_FACTOR)
    for i in pairs(self.active_states) do
        if self.active_states[i] ~= self.current_state then
            self.active_states[i]:update(self, dt)
        end
    end
    return self.current_state:update(self, dt)
end

return GameState
