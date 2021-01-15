local FrameState = {}
FrameState.__index = FrameState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

function FrameState:init(next_state)
    local this = {
        dtotal = 0,             -- Delta time total
        ticks_advanced = TICKS_ADVANCE_MAX,     -- Number of ticks left to go before update
        next_state = next_state,

        frames = {},
    }
    setmetatable(this, self)

    return this
end

function FrameState:key_pressed(game_state, key)
end

function FrameState:update(game_state, dt)
    self.dtotal = self.dtotal + dt
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE
        self.ticks_advanced = self.ticks_advanced - 1

        if self.ticks_advanced > 0 then
            -- Wait til next time.
            return
        end

        local frames = game_state.player_info:get_frames()
        for i=1, #frames do
            frames[i]:update(game_state, dt)
        end
    end
end

function FrameState:render(renderer, game_state)
    local frames = game_state.player_info:get_frames()
    for i=1, #frames do
        local frame = frames[i]
        local accum = 1

        renderer:set_color("gray")
        accum = accum + renderer:draw_string("Frame " .. tostring(i) .. ": ", i, accum)

        if frame:get_deployed() then
            renderer:set_color("white")
            accum = accum + renderer:draw_string(frame:get_x() .. ", " .. frame:get_y(), i, accum)
        else
            renderer:set_color("gray")
            accum = accum + renderer:draw_string("In Hold", i, accum)
        end
    end
end

return FrameState
