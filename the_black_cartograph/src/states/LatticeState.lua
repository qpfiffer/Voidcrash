local LatticeState = {}
LatticeState.__index = LatticeState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

function LatticeState:init(next_state)
    local this = {
        dtotal = 0,
        ticks_advanced = TICKS_ADVANCE_MAX,
        char_update_constant = 0,
        screen_state = {}
    }
    setmetatable(this, self)

    return this
end

function LatticeState:key_pressed(game_state, key)
end

function LatticeState:update(game_state, dt)
    self.dtotal = self.dtotal + dt
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE
        self.ticks_advanced = self.ticks_advanced - 1

        if self.ticks_advanced > 0 then
            -- Wait til next time.
            return
        end

        -- Reset the counter.
        self.char_update_constant = self.char_update_constant + 1

        local max_total_added = 3
        local total_added_so_far = 0
    end
end

function LatticeState:render(renderer)
        local block_width = 128
        local block_height = 72
        local grid_size = 3

        local width = love.graphics.getWidth()
        local height = love.graphics.getHeight()
        local multiplier = 2

        local y_padding = 64

        renderer:set_color("white")
        love.graphics.translate(width/2, height/8)
        for x = 1, grid_size do
           for y = 1, grid_size do
               for z = 1, grid_size do
                    -- Top
                    love.graphics.line(
                        (x - z) * block_width,
                        (y + z) * block_height + (y * y_padding),
                        (x - z + 1) * block_width,
                        (y + z) * block_height + (y * y_padding))
                    -- Left
                    love.graphics.line(
                        (x - z - 1) * block_width,
                        (y + z + 1) * block_height + (y * y_padding),
                        (x - z) * block_width,
                        (y + z) * block_height + (y * y_padding))
                    -- Right
                    love.graphics.line(
                        (x - z) * block_width,
                        (y + z + 1) * block_height + (y * y_padding),
                        (x - z + 1) * block_width,
                        (y + z) * block_height + (y * y_padding))
                    -- Bottom
                    love.graphics.line(
                        (x - z - 1) * block_width,
                        (y + z + 1) * block_height + (y * y_padding),
                        (x - z) * block_width,
                        (y + z + 1) * block_height + (y * y_padding))
               end
           end
        end
        love.graphics.origin()
end

return LatticeState
