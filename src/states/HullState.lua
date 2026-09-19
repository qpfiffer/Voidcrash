local Screen = require("src/Screen")
local HullState = Screen.extend()

local constants = require("src/Constants")
local hull_queries = require("src/sim/hull_queries")

function HullState:init()
    local this = {
        selected_idx = 1,
    }
    setmetatable(this, self)

    return this
end

function HullState:get_name()
    return "HUL"
end

function HullState:uses_blink()
    return true
end

function HullState:key_pressed(game_state, key)
    if key == "right" then
        self.selected_idx = self.selected_idx + 1
    elseif key == "left" then
        self.selected_idx = self.selected_idx - 1
    end

    if self.selected_idx > 3 then
        self.selected_idx = 1
    elseif self.selected_idx < 1 then
        self.selected_idx = 3
    end
end

function HullState:_draw_power_used_pane(renderer, game_state)
    local accum = 2
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("POWER", row, accum)
    row = row + 1

    local world = game_state.world
    local items = hull_queries.powered(world)
    for i=1, #items do
        renderer:set_color("gray")
        accum = accum + renderer:draw_string("* " .. world:get(items[i], "Named").name, row, accum)

        row = row + 1
        accum = 2
    end

    renderer:set_color("gray")
    accum = accum + renderer:draw_string("PWR: ", row, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(hull_queries.power_usage(world)), row, accum)
end

function HullState:_draw_cargo_pane(renderer, game_state)
    local accum_start = constants.MAP_X_MAX/3 + 2
    local accum = accum_start
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("CARGO", row, accum)
    row = row + 1

    local world = game_state.world
    local items = hull_queries.cargo(world)
    for i=1, #items do
        renderer:set_color("gray")
        accum = accum + renderer:draw_string("* " .. world:get(items[i], "Named").name, row, accum)

        row = row + 1
        accum = accum_start
    end

    renderer:set_color("gray")
    accum = accum + renderer:draw_string("TON: ", row, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(hull_queries.cargo_tonnage(world)), row, accum)
end

function HullState:_draw_fabricator_pane(renderer, game_state)
    local accum_start = 2 * (constants.MAP_X_MAX/3) + 3
    local accum = accum_start
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("FAB", row, accum)
    row = row + 1

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

    local blink_on = game_state.clock:blink_on()
    local color = "white"
    if blink_on and self.selected_idx == 1 then
        color = "red"
    end
    renderer:render_window(x, y, w - 4, h, "black", color)

    color = "white"
    if blink_on and self.selected_idx == 2 then
        color = "red"
    end
    renderer:render_window(constants.MAP_X_MAX/3 + 1, y, w - 3, h, "black", color)

    color = "white"
    if blink_on and self.selected_idx == 3 then
        color = "red"
    end
    renderer:render_window(2 * (constants.MAP_X_MAX/3) + 2, y, w - 3, h, "black", color)

    self:_draw_power_used_pane(renderer, game_state)
    self:_draw_cargo_pane(renderer, game_state)
    self:_draw_fabricator_pane(renderer, game_state)
end

return HullState
