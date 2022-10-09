local LatticeState = {}
LatticeState.__index = LatticeState

local constants = require("src/Constants")

local BLINK_TICK_COUNT = 20
local BLINK_TICKER_COUNTDOWN = 8

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

local LATTICE_GRID_SIZE = 3
local LATTICE_BLOCK_WIDTH = 128
local LATTICE_BLOCK_HEIGHT = 72
local LATTICE_X_TWEAK = 12
local LATTICE_Y_PADDING = 72

local SELECT_MODES = {"x", "y", "z"}

function LatticeState:init()
    local this = {
        dtotal = 0,
        ticks_advanced = TICKS_ADVANCE_MAX,
        screen_state = {},

        blink_cursor_on = true,
        blink_ticker_countdown = BLINK_TICKER_COUNTDOWN,

        selected = {1, 1, 1},
        select_mode_idx = 1,
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
    if key == "return" then
        self.select_mode_idx = self.select_mode_idx + 1
        return
    end

    if SELECT_MODES[self.select_mode_idx] == "x" then
        if key == "left" then
            self.selected[1] = self.selected[1] - 1
            self.blink_cursor_on = true
        elseif key == "right" then
            self.selected[1] = self.selected[1] + 1
            self.blink_cursor_on = true
        end
    end
    if SELECT_MODES[self.select_mode_idx] == "y" then
        if key == "up" then
            self.selected[2] = self.selected[2] - 1
            self.blink_cursor_on = true
        elseif key == "down" then
            self.selected[2] = self.selected[2] + 1
            self.blink_cursor_on = true
        end
    end

    self:_ensure_grid_size_selected(1)
    self:_ensure_grid_size_selected(2)

    -- Clamp select_mode_idx to bounds of SELECT_MODES.
    if self.select_mode_idx > #SELECT_MODES then
        self.select_mode_idx = 1
    elseif self.select_mode_idx <= 0 then
        self.selected[idx] = #SELECT_MODES - 1
    end
end

function LatticeState:update(game_state, dt)
    self.dtotal = self.dtotal + dt
    local tick_modifier = 16
    local modified_tick = constants.TICKER_RATE / tick_modifier
    if self.dtotal >= modified_tick then
        self.dtotal = self.dtotal - modified_tick
        self.ticks_advanced = self.ticks_advanced - 1

        if self.ticks_advanced > 0 then
            -- Wait til next time.
            return
        end

        if not game_state:get_paused() then
            local player_info = game_state:get_player_info()
            player_info:set_current_lattice_step(player_info:get_current_lattice_step() + 0.0002)
        end

        self.ticks_advanced = BLINK_TICK_COUNT

        self.blink_ticker_countdown = self.blink_ticker_countdown - 1
        if self.blink_ticker_countdown <= 0 then
            self.blink_cursor_on = not self.blink_cursor_on
            self.blink_ticker_countdown = BLINK_TICKER_COUNTDOWN
        end
    end
end

function LatticeState:_render_lattice_surface_tile(renderer, game_state, connected, x, y, z, x_move)
    local select_mode = SELECT_MODES[self.select_mode_idx]

    -- Top
    if connected and self.blink_cursor_on and (z - 1) == self.selected[2] then
        if select_mode == "y" then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "z" then
            renderer:set_color("yellow")
            love.graphics.setLineWidth(3)
        end
    end
    love.graphics.line(
        ((x - z) * LATTICE_BLOCK_WIDTH) + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
        (x - z + 1) * LATTICE_BLOCK_WIDTH + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING))
    renderer:set_color("white")
    love.graphics.setLineWidth(1)

    if connected and self.blink_cursor_on and (x - 1) == self.selected[1] then
        if select_mode == "x" then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "y" or select_mode == "z" then
            renderer:set_color("yellow")
            love.graphics.setLineWidth(3)
        end
    end
    -- Left
    love.graphics.line(
        (x - z - 1) * LATTICE_BLOCK_WIDTH - LATTICE_X_TWEAK - x_move,
        (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
        ((x - z) * LATTICE_BLOCK_WIDTH) + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING))
    renderer:set_color("white")
    love.graphics.setLineWidth(1)

    if connected and self.blink_cursor_on and x == self.selected[1] then
        if select_mode == "x" then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "y" or select_mode == "z" then
            renderer:set_color("yellow")
            love.graphics.setLineWidth(3)
        end
    end
    -- Right
    love.graphics.line(
        ((x - z) * LATTICE_BLOCK_WIDTH) - LATTICE_X_TWEAK - x_move,
        (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
        (x - z + 1) * LATTICE_BLOCK_WIDTH + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING))
    renderer:set_color("white")
    love.graphics.setLineWidth(1)

    if connected and self.blink_cursor_on and z == self.selected[2] then
        if select_mode == "y" then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "z" then
            renderer:set_color("yellow")
            love.graphics.setLineWidth(3)
        end
    end
    -- Bottom
    love.graphics.line(
        (x - z - 1) * LATTICE_BLOCK_WIDTH - LATTICE_X_TWEAK - x_move,
        (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
        ((x - z) * LATTICE_BLOCK_WIDTH) - LATTICE_X_TWEAK - x_move,
        (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING))
    renderer:set_color("white")
    love.graphics.setLineWidth(1)
end

function LatticeState:_render_lattice_vertical_lines(renderer, game_state, connected, x, y, z, x_move)
    local select_mode = SELECT_MODES[self.select_mode_idx]
    if y ~= LATTICE_GRID_SIZE + 1 then
        -- Right
        if connected and self.blink_cursor_on then
            if select_mode == "x" and x == self.selected[1] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "y" and (z - 1) == self.selected[2] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "z" and x == self.selected[1] then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
        love.graphics.line(
            (x - z + 1) * LATTICE_BLOCK_WIDTH + LATTICE_X_TWEAK - x_move,
            (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
            (x - z + 1) * LATTICE_BLOCK_WIDTH + LATTICE_X_TWEAK - x_move,
            (y + z) * LATTICE_BLOCK_HEIGHT + ((2 + y) * LATTICE_Y_PADDING))
        renderer:set_color("white")
        love.graphics.setLineWidth(1)

        -- Left
        if connected and self.blink_cursor_on then
            if select_mode == "x"  and (x - 1) == self.selected[1] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "y" and z == self.selected[2] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "z" then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
        love.graphics.line(
            (x - z - 1) * LATTICE_BLOCK_WIDTH - LATTICE_X_TWEAK - x_move,
            (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
            (x - z - 1) * LATTICE_BLOCK_WIDTH - LATTICE_X_TWEAK - x_move,
            (y + z + 1) * LATTICE_BLOCK_HEIGHT + ((2 + y) * LATTICE_Y_PADDING))
        renderer:set_color("white")
        love.graphics.setLineWidth(1)

        -- Bottom
        if connected and self.blink_cursor_on then
            if select_mode == "x" and x == self.selected[1] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "y" and z == self.selected[2] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "z" then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
        love.graphics.line(
            ((x - z) * LATTICE_BLOCK_WIDTH) - LATTICE_X_TWEAK - x_move,
            (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
            ((x - z) * LATTICE_BLOCK_WIDTH) - LATTICE_X_TWEAK - x_move,
            (y + z + 1) * LATTICE_BLOCK_HEIGHT + ((2 + y) * LATTICE_Y_PADDING))
        renderer:set_color("white")
        love.graphics.setLineWidth(1)

        -- Top
        -- XXX: This needs to flash on both self.selected[2] and self.selected[1].
        if connected and self.blink_cursor_on then
            --print("SELECT MODE: " .. select_mode .. " X: " .. tostring(x) .. " Z: " .. tostring(z))
            --print("SELECTED 1 & 2: " .. tostring(self.selected[1]) .. ", " .. tostring(self.selected[2]))
            if select_mode == "x" and (x - 1) == self.selected[1] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "y" and (z - 1) == self.selected[2] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "z" then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
        love.graphics.line(
            ((x - z) * LATTICE_BLOCK_WIDTH) + LATTICE_X_TWEAK - x_move,
            (y + z + 1) * LATTICE_BLOCK_HEIGHT + ((y - 1) * LATTICE_Y_PADDING),
            ((x - z) * LATTICE_BLOCK_WIDTH) + LATTICE_X_TWEAK - x_move,
            (y + z + 1) * LATTICE_BLOCK_HEIGHT + ((y + 1) * LATTICE_Y_PADDING))
        renderer:set_color("white")
        love.graphics.setLineWidth(1)
    end
end

function LatticeState:_render_lattice(renderer, game_state, connected)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    renderer:set_color("white")
    love.graphics.translate(width/2, height/16 - 150)

    for x = 1, LATTICE_GRID_SIZE do
        for y = 1, LATTICE_GRID_SIZE + 1 do
            for z = 1, LATTICE_GRID_SIZE do
                local x_move = (LATTICE_X_TWEAK * 2) * (z - 1)

                self:_render_lattice_surface_tile(renderer, game_state, connected, x, y, z, x_move)
                self:_render_lattice_vertical_lines(renderer, game_state, connected, x, y, z, x_move)
            end
        end
    end
end

function LatticeState:render(renderer, game_state)
    renderer:draw_traumae_string("LATTICE CONN", 1, 0)
    renderer:draw_string("Lattice Sleeper Conn.", 2, 0)
    renderer:draw_string("CONN: ", 3, 0)

    local player_info = game_state:get_player_info()
    local connected = player_info:get_lattice_intensity(player_info.overmap_x, player_info.overmap_y) < (constants.LATTICE_MINUMUM_INTENSITY + 200)
    -- local connected = true
    if connected then
        renderer:set_color("green")
        renderer:draw_string("CONNECTED", 3, 5)
    else
        renderer:set_color("red")
        renderer:draw_string("DISCONNECTED", 3, 5)
    end

    self:_render_lattice(renderer, game_state, connected)

    love.graphics.origin()
end

return LatticeState
