local RadioState = {}
RadioState.__index = RadioState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

function RadioState:init(next_state)
    local this = {
        dtotal = 0,             -- Delta time total
        ticks_advanced = TICKS_ADVANCE_MAX,     -- Number of ticks left to go before update
        next_state = next_state,
    }
    setmetatable(this, self)

    return this
end

function RadioState:key_pressed(game_state, key)
end

function RadioState:update(game_state, dt)
    self.dtotal = self.dtotal + dt
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE
        self.ticks_advanced = self.ticks_advanced - 1

        if self.ticks_advanced > 0 then
            -- Wait til next time.
            return
        end

        -- Do something.

    end
end

function RadioState:_draw_radio_messages(renderer, game_state)
    local accum = 2
    local row = 2

    renderer:set_color("white")
    renderer:draw_string("Received", row, accum)
    row = row + 1

    local messages = game_state.player_info.radio:get_messages()
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
    local h = constants.MAP_Y_MAX - 10

    renderer:render_window(x, y, w - 4, h, "black", "white")

    self:_draw_radio_messages(renderer, game_state)
end

return RadioState
