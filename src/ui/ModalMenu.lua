local ModalMenu = {}
ModalMenu.__index = ModalMenu
-- This should render a menu with selectable components. Update should move the selected item up and down.
-- It should take callbacks (Maybe?) So that it can alter state from a calling... thing.

function ModalMenu:init(game_state, x, y, items, exit_callback)
    local this = {
        x = x,
        y = y,
        items = items,
        selected_idx = 1,
        exit_callback = exit_callback
    }
    setmetatable(this, self)

    for i in pairs(items) do
        local item = items[i]
        if item["enabled"] then
            this.selected_idx = i
            break
        end
    end

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
    local w = 0
    local h = #self.items

    for i=1, #self.items do
        local item = self.items[i]
        local len = string.len(item["name"])
        if len > w then
            w = len
        end
    end

    renderer:render_window(self.x, self.y, w + 2, h, "black", "white")

    local accum_initial = self.x + 2 -- 2x sides
    local row = self.y + 1
    local accum = accum_initial
    for i=1, #self.items do
        local item = self.items[i]
        renderer:set_color("white")
        if not item["enabled"] then
            renderer:set_color("grayer")
        end
        if i == self.selected_idx then
            accum = accum + renderer:draw_string("* ", row, accum)
        else
            accum = accum + 2 -- strlen("* ")
        end

        accum = accum + renderer:draw_string(item["name"], row, accum)

        row = row + 1
        accum = accum_initial
    end
end

return ModalMenu
