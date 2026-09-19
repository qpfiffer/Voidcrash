local ModalMenu = {}
ModalMenu.__index = ModalMenu
-- A popup list of things to pick from.
-- items: {{name = "...", enabled = bool, callback = function() end}, ...}
-- Disabled items are shown grayed out; they can't be selected or fired.

function ModalMenu:init(x, y, items, fg_color, bg_color)
    local this = {
        x = x,
        y = y,
        items = items,
        selected_idx = nil,
        fg_color = fg_color,
        bg_color = bg_color,
    }
    setmetatable(this, self)

    this.selected_idx = this:_next_enabled(0, 1)

    return this
end

-- The first enabled item after `from` going in `direction` (1 or -1), wrapping
-- around. nil if nothing is enabled at all.
function ModalMenu:_next_enabled(from, direction)
    local count = #self.items
    for offset=1, count do
        local idx = ((from - 1 + offset * direction) % count) + 1
        if self.items[idx].enabled then
            return idx
        end
    end
    return nil
end

function ModalMenu:key_pressed(game_state, key)
    if not self.selected_idx then
        return
    end

    if key == "return" then
        local item = self.items[self.selected_idx]
        if item.enabled and item.callback then
            item.callback()
        end
    elseif key == "up" then
        self.selected_idx = self:_next_enabled(self.selected_idx, -1)
    elseif key == "down" then
        self.selected_idx = self:_next_enabled(self.selected_idx, 1)
    end
end

function ModalMenu:render(renderer)
    local w = 0
    local h = #self.items

    for i=1, #self.items do
        local len = string.len(self.items[i].name)
        if len > w then
            w = len
        end
    end

    local fg_color = self.fg_color or "white"
    local bg_color = self.bg_color or "black"
    renderer:render_window(self.x, self.y, w + 2, h, bg_color, fg_color)

    local column = self.x + 2 -- 2x sides
    for i=1, #self.items do
        local item = self.items[i]
        local row = self.y + i

        renderer:set_color(item.enabled and "white" or "grayer")
        if i == self.selected_idx then
            renderer:draw_string("* ", row, column)
        end
        renderer:draw_string(item.name, row, column + 2) -- strlen("* ")
    end
end

return ModalMenu
