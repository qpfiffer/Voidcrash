local GameState = {}
GameState.__index = GameState

local constants= require("src/Constants")
local PlayerInfo = require("src/PlayerInfo")

function GameState:init(initial_state)
    local this = {
        current_state = initial_state,

        player_info = PlayerInfo:init(),
        paused = false,
        menu_open = false
    }
    setmetatable(this, self)

    return this
end

function GameState:key_pressed(key)
    -- if key == "escape" then
    --     -- TODO: push_state menu
    --     love.event.quit()
    -- end

    return self.current_state:key_pressed(self, key)
end

function GameState:push_state(new_state)
    -- TBD
    self.current_state = new_state
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
    return self.current_state:update(self, dt)
end

return GameState
