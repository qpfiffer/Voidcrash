local HullState = {}
HullState.__index = HullState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

function HullState:init(next_state)
    local this = {
        dtotal = 0,             -- Delta time total
        ticks_advanced = TICKS_ADVANCE_MAX,     -- Number of ticks left to go before update
        next_state = next_state,
    }
    setmetatable(this, self)

    return this
end

function HullState:key_pressed(game_state, key)
end

function HullState:update(game_state, dt)
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

function HullState:render(renderer)
    local x = 1
    local y = 1
    local w = constants.MAP_X_MAX/3
    local h = constants.MAP_Y_MAX - y

    renderer:render_window(x, y, w, h, "black", "white")
    renderer:render_window(constants.MAP_X_MAX/3, y, w, h, "black", "white")
    renderer:render_window(2 * (constants.MAP_X_MAX/3), y, w, h, "black", "white")
end

return HullState
