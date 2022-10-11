local SleeperDialog = {}
SleeperDialog.__index = SleeperDialog

local constants = require("src/Constants")

function SleeperDialog:_new_item(text)
    return {
        text = text,
        current_text_idx = 0,
    }
end

function SleeperDialog:init(game_state)
    local this = {
        items = {},

        current_text_item_idx = 1,
        ticker = 1,
    }
    setmetatable(this, self)

    this.items = {
        self:_new_item("the harvest moon is"),
        self:_new_item("good for black tides"),
        self:_new_item("and a dead wind blows"),
    }

    return this
end

function SleeperDialog:handle_keys(game_state, dt)
end

function SleeperDialog:key_pressed(game_state, key)
    --if key == "return" then
    --    self.items[self.selected_idx]["callback"](self.bonus_data)
    --elseif key == "up" then
    --    self.selected_idx = self.selected_idx - 1
    --elseif key == "down" then
    --    self.selected_idx = self.selected_idx + 1
    --end

    --if self.selected_idx > #self.items then
    --    self.selected_idx = self.first_enabled_idx
    --elseif self.selected_idx < self.first_enabled_idx then
    --    self.selected_idx = #self.items
    --end
end

function SleeperDialog:update(game_state)
    local current_item = self.items[self.current_text_item_idx]

    if current_item.current_text_idx < string.len(current_item.text) then
        current_item.current_text_idx = current_item.current_text_idx + 1
    else
        self.current_text_item_idx = self.current_text_item_idx + 1
    end

    if self.current_text_item_idx > #self.items then
        self.current_text_item_idx = #self.items
    end
end

function SleeperDialog:render(renderer, game_state)
    local x = 5
    local y = 5
    local w = constants.MAP_X_MAX - 10
    local h = constants.MAP_Y_MAX - 12

    local fg_color = "white"
    local bg_color = "black"
    renderer:render_window(x, y, w + 2, h, bg_color, fg_color)

    local accum_initial = x - 2 -- Hand-picked "Move traumae over to the left" offset
    local row = h + 9
    local accum = accum_initial
    for i=1, #self.items do
        local item = self.items[i]
        renderer:set_color("white")

        local substr = string.sub(item.text, 1, item.current_text_idx)
        accum = accum + renderer:draw_traumae_string(substr, row, accum)

        row = row - 1
        accum = accum_initial
    end
end

return SleeperDialog
