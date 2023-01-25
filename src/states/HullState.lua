local HullState = {}
HullState.__index = HullState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

local BLINK_TICK_COUNT = 20

function HullState:init(next_state)
    local this = {
        dtotal = 0,
        ticks_advanced = BLINK_TICK_COUNT,
        next_state = next_state,

        blink_cursor_on = true,

        selected_idx = 1,
    }
    setmetatable(this, self)

    return this
end

function HullState:get_name()
    return "HUL"
end

function HullState:key_pressed(game_state, key)
    if key == "right" then
        self.selected_idx = self.selected_idx + 1
    elseif key == "left" then
        self.selected_idx = self.selected_idx - 1
    end

    self.blink_cursor_on = true

    if self.selected_idx > 3 then
        self.selected_idx = 1
    elseif self.selected_idx < 1 then
        self.selected_idx = 3
    end
end

function HullState:update(game_state, dt)
    self.dtotal = self.dtotal + dt
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE
        self.ticks_advanced = self.ticks_advanced - 1

        if self.ticks_advanced <= 0 then
            -- Reset the counter.
            self.ticks_advanced = BLINK_TICK_COUNT
            self.blink_cursor_on = not self.blink_cursor_on
        end

        -- Do something.

    end
end

function HullState:_draw_power_used_pane(renderer, game_state)
    local accum = 2
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("POWER", row, accum)
    row = row + 1

    local items = game_state.player_info.hull:get_power_items()
    for i in pairs(items) do
        local active_power_item = items[i]
        renderer:set_color("gray")
        accum = accum + renderer:draw_string("* " .. active_power_item:get_name(), row, accum)

        row = row + 1
        accum = 2
    end

    renderer:set_color("gray")
    accum = accum + renderer:draw_string("PWR: ", row, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(game_state.player_info.hull:get_power_usage()), row, accum)
end

function HullState:_draw_cargo_pane(renderer, game_state)
    local accum_start = constants.MAP_X_MAX/3 + 2
    local accum = accum_start
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("CARGO", row, accum)
    row = row + 1

    local items = game_state.player_info.hull:get_cargo()
    for i in pairs(items) do
        local cargo_item = items[i]
        renderer:set_color("gray")
        accum = accum + renderer:draw_string("* " .. cargo_item:get_name(), row, accum)

        row = row + 1
        accum = accum_start
    end

    renderer:set_color("gray")
    accum = accum + renderer:draw_string("TON: ", row, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(game_state.player_info.hull:get_cargo_usage()), row, accum)
end

function HullState:_draw_fabricator_pane(renderer, game_state)
    local accum_start = 2 * (constants.MAP_X_MAX/3) + 3
    local accum = accum_start
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("FAB", row, accum)
    row = row + 1

    -- local items = game_state.player_info:get_cargo()
    -- for i in pairs(items) do
    --     local cargo_item = items[i]
    --     renderer:set_color("gray")
    --     accum = accum + renderer:draw_string("* " .. cargo_item:get_name(), row, accum)

    --     row = row + 1
    --     accum = accum_start
    -- end

    renderer:set_color("gray")
    accum = accum + renderer:draw_string("JOB: ", row, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string("n/a", row, accum)
end

function HullState:render(renderer, game_state)
    local x = 1
    local y = 1
    local w = constants.MAP_X_MAX/3
    local h = constants.MAP_Y_MAX - y - 10

    renderer:set_color("white")

    local color = "white"
    if self.blink_cursor_on and self.selected_idx == 1 then
        color = "red"
    end
    renderer:render_window(x, y, w - 4, h, "black", color)

    color = "white"
    if self.blink_cursor_on and self.selected_idx == 2 then
        color = "red"
    end
    renderer:render_window(constants.MAP_X_MAX/3 + 1, y, w - 3, h, "black", color)

    color = "white"
    if self.blink_cursor_on and self.selected_idx == 3 then
        color = "red"
    end
    renderer:render_window(2 * (constants.MAP_X_MAX/3) + 2, y, w - 3, h, "black", color)

    self:_draw_power_used_pane(renderer, game_state)
    self:_draw_cargo_pane(renderer, game_state)
    self:_draw_fabricator_pane(renderer, game_state)
end

return HullState
