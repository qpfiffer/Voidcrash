local GameState = {}
GameState.__index = GameState

function GameState:init(initial_state)
    local this = {
        current_state = initial_state
    }
    setmetatable(this, self)

    return this
end

function GameState:set_current_state(new_state)
    self.current_state = new_state
end

function GameState:get_current_state()
    return self.current_state
end

function GameState:render_current_state(renderer)
    return self.current_state:render(renderer)
end

return GameState
