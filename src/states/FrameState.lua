local FrameState = {}
FrameState.__index = FrameState

local constants = require("src/Constants")

local ObjectType = require("src/objects/ObjectType")

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
    end
end

function FrameState:render(renderer, game_state)
    local frames = game_state.player_info:get_cargo_items_of_type(ObjectType.FRAME)
    local deployed_frames = game_state.player_info:get_world_objects_of_type(ObjectType.FRAME)
    local tables = {frames, deployed_frames}

    local row = 0
    for i=1, #tables do
        local table = tables[i]
        for j=1, #table do
            local frame = table[j]
            local accum = 1
            row = row + 1

            renderer:set_color("gray")
            accum = accum + renderer:draw_string("* Frame " .. tostring(frame:get_name()) .. ": ", row, accum)

            if frame:get_deployed() then
                renderer:set_color("white")
                accum = accum + renderer:draw_string(frame:get_x() .. ", " .. frame:get_y(), row, accum)
            else
                renderer:set_color("gray")
                accum = accum + renderer:draw_string("In Hold", row, accum)
            end
        end
    end
end

return FrameState
