local LatticeState = {}
LatticeState.__index = LatticeState

local constants = require("src/Constants")

local BLINK_TICK_COUNT = 20

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3


local LATTICE_GRID_SIZE = 3

function LatticeState:init()
    local this = {
        dtotal = 0,
        ticks_advanced = TICKS_ADVANCE_MAX,
        char_update_constant = 0,
        screen_state = {},

        blink_cursor_on = true,
        ticks_advanced = BLINK_TICK_COUNT,
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

        self.ticks_advanced = BLINK_TICK_COUNT
        self.blink_cursor_on = not self.blink_cursor_on

        self.char_update_constant = self.char_update_constant + 1
    end
end

function _draw_iso_square(renderer, x, y, z)
    local block_width = 128
    local block_height = 72

    local y_padding = 64

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

function LatticeState:render(renderer, game_state)
    renderer:draw_traumae_string("LATTICE CONN", 1, 0)
    renderer:draw_string("Lattice Sleeper Conn.", 2, 0)
    renderer:draw_string("CONN:", 3, 0)

    local selected = {2, 2, 2}

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    renderer:set_color("white")
    love.graphics.translate(width/2, height/8)
    for x = 1, LATTICE_GRID_SIZE do
        if self.blink_cursor_on and x == selected[1] then
            renderer:set_color("red")
        else
            renderer:set_color("white")
        end
        for y = 1, LATTICE_GRID_SIZE do
            for z = 1, LATTICE_GRID_SIZE do
                _draw_iso_square(renderer, x, y, z)
            end
        end
    end

    -- if self.blink_cursor_on then
    --     renderer:set_color("red")
    --     _draw_iso_square(renderer, selected[1], selected[2], selected[3])
    -- end

    love.graphics.origin()
end

return LatticeState
