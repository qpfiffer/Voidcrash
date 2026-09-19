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

    -- The newest messages that fit in the window.
    local world = game_state.world
    local messages = world:get(world.res.radio, "RadioLog").messages
    local visible_rows = constants.MAP_Y_MAX - 3
    renderer:set_color("gray")
    for i=math.max(1, #messages - visible_rows + 1), #messages do
        renderer:draw_string("* " .. messages[i], row, accum)
        row = row + 1
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
