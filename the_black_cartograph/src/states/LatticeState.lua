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
        selected = {1, 1},
        select_mode = "x",
        ticks_advanced = BLINK_TICK_COUNT,
    }
    setmetatable(this, self)

    return this
end

function LatticeState:_ensure_grid_size_selected(idx)
    if self.selected[idx] > LATTICE_GRID_SIZE then
        self.selected[idx] = 0
    elseif self.selected[idx] < 0 then
        self.selected[idx] = LATTICE_GRID_SIZE
    end
end

function LatticeState:key_pressed(game_state, key)
    if key == "left" then
        self.select_mode = "x"
        self.selected[1] = self.selected[1] - 1
    elseif key == "right" then
        self.select_mode = "x"
        self.selected[1] = self.selected[1] + 1
    elseif key == "up" then
        self.select_mode = "y"
        self.selected[2] = self.selected[2] - 1
    elseif key == "down" then
        self.select_mode = "y"
        self.selected[2] = self.selected[2] + 1
    end

    self:_ensure_grid_size_selected(1)
    self:_ensure_grid_size_selected(2)
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

function LatticeState:render(renderer, game_state)
    renderer:draw_traumae_string("LATTICE CONN", 1, 0)
    renderer:draw_string("Lattice Sleeper Conn.", 2, 0)
    renderer:draw_string("CONN:", 3, 0)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    renderer:set_color("white")
    love.graphics.translate(width/2, height/8)
    for x = 1, LATTICE_GRID_SIZE do
        for y = 1, LATTICE_GRID_SIZE do
            for z = 1, LATTICE_GRID_SIZE do
                local block_width = 128
                local block_height = 72

                local y_padding = 64

                -- Top
                if self.blink_cursor_on and self.select_mode == "y" and (z - 1) == self.selected[2] then
                    renderer:set_color("red")
                end
                love.graphics.line(
                    (x - z) * block_width,
                    (y + z) * block_height + (y * y_padding),
                    (x - z + 1) * block_width,
                    (y + z) * block_height + (y * y_padding))
                renderer:set_color("white")

                if self.blink_cursor_on and self.select_mode == "x" and (x - 1) == self.selected[1] then
                    renderer:set_color("red")
                end
                -- Left
                love.graphics.line(
                    (x - z - 1) * block_width,
                    (y + z + 1) * block_height + (y * y_padding),
                    (x - z) * block_width,
                    (y + z) * block_height + (y * y_padding))
                renderer:set_color("white")

                if self.blink_cursor_on and self.select_mode == "x" and x == self.selected[1] then
                    renderer:set_color("red")
                end
                -- Right
                love.graphics.line(
                    (x - z) * block_width,
                    (y + z + 1) * block_height + (y * y_padding),
                    (x - z + 1) * block_width,
                    (y + z) * block_height + (y * y_padding))
                renderer:set_color("white")

                if self.blink_cursor_on and self.select_mode == "y" and z == self.selected[2] then
                    renderer:set_color("red")
                end
                -- Bottom
                love.graphics.line(
                    (x - z - 1) * block_width,
                    (y + z + 1) * block_height + (y * y_padding),
                    (x - z) * block_width,
                    (y + z + 1) * block_height + (y * y_padding))
                renderer:set_color("white")
            end
        end
    end

    love.graphics.origin()
end

return LatticeState
