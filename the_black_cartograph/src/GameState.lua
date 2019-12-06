local GameState = {}
GameState.__index = GameState

function GameState:init(initial_state)
    local this = {
        current_state = initial_state
    }
    setmetatable(this, self)

    return this
end

function GameState:key_pressed(key)
    if key == "escape" then
        -- TODO: push_state menu
        love.event.quit()
    end

    return self.current_state:key_pressed(key)
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

function GameState:render_current_state(renderer)
    return self.current_state:render(renderer)
end

function GameState:update_current_state(dt)
    return self.current_state:update(self, dt)
end

return GameState
