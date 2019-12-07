local GameState = {}
GameState.__index = GameState

local Stack = require("src/Stack")

function GameState:init(initial_state)
    local this = {
        current_state = Stack:init(),

        player_info = nil
    }
    setmetatable(this, self)

    this.current_state:push(initial_state)

    return this
end

function GameState:key_pressed(key)
    if key == "escape" then
        -- TODO: push_state menu
        love.event.quit()
    end

    function f(state)
        state:key_pressed(self, key)
    end

    self.current_state:map(f)
end

function GameState:push_state(new_state)
    -- TBD
    return self.current_state:push(new_state)
end

function GameState:pop_state()
    return self.current_state:pop()
end

function GameState:get_current_state()
    return self.current_state:peek()
end

function GameState:set_player_info(pi)
    self.player_info = pi
end

function GameState:get_player_info()
    return self.pi
end

function GameState:render_current_state(renderer)
    function f(state)
        state:render(renderer)
    end

    self.current_state:map(f)
end

function GameState:update_current_state(dt)
    function f(state)
        state:update(self, dt)
    end

    self.current_state:map(f)
end

return GameState
