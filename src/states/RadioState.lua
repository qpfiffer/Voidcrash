local Screen = require("src/Screen")
local RadioState = Screen.extend()

local constants = require("src/Constants")

function RadioState:init()
    local this = {}
    setmetatable(this, self)

    return this
end

function RadioState:get_name()
    return "RAD"
end

function RadioState:_draw_radio_messages(renderer, game_state)
    local accum = 2
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("Received", row, accum)
    row = row + 1

    local messages = game_state.player_info.hull.radio:get_messages()
    for i in pairs(messages) do
        local message = messages[i]
        renderer:set_color("gray")
        accum = accum + renderer:draw_string("* " .. message, row, accum)

        row = row + 1
        accum = 2
    end
end

function RadioState:render(renderer, game_state)
    local x = 1
    local y = 1
    local w = constants.MAP_X_MAX
    local h = constants.MAP_Y_MAX - 1

    renderer:render_window(x, y, w - 4, h, "black", "white")

    self:_draw_radio_messages(renderer, game_state)
end

return RadioState
