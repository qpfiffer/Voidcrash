local ModalMenu = {}
ModalMenu.__index = ModalMenu
-- This should render a menu with selectable components. Update should move the selected item up and down.
-- It should take callbacks (Maybe?) So that it can alter state from a calling... thing.

function ModalMenu:init(game_state, x, y, items, exit_callback)
    local this = {
        x = x,
        y = y,
        items = items,
        exit_callback = exit_callback
    }
    setmetatable(this, self)

    return this
end

function ModalMenu:handle_keys(game_state, dt)
end

function ModalMenu:key_pressed(game_state, key)
    if key == "return" then
        return self.exit_callback()
    end
end

function ModalMenu:render(renderer, game_state)
    local w = 10
    local h = 5
    renderer:render_window(self.x, self.y, w, h, "black", "white")
end

return ModalMenu
