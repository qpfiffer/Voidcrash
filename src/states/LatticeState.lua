local LatticeState = {}
LatticeState.__index = LatticeState

local constants = require("src/Constants")
local SleeperDialog = require("src/ui/SleeperDialog")

local BLINK_TICK_COUNT = 20
local BLINK_TICKER_COUNTDOWN = 8

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

local LATTICE_GRID_SIZE = 3
local LATTICE_BLOCK_WIDTH = 128
local LATTICE_BLOCK_HEIGHT = 72
local LATTICE_X_TWEAK = 12
local LATTICE_Y_PADDING = 72

local SELECT_MODES = {"x", "y", "z"}

local LTC_STATE_SELECTING = 1
local LTC_STATE_SELECTED = 2

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

        lattice_state = LTC_STATE_SELECTING,
        connected_window = nil,
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
    local select_mode = SELECT_MODES[self.select_mode_idx]

    if key == "return" then
        if select_mode == "z" then
            self.lattice_state = LTC_STATE_SELECTED
            self.connected_window = SleeperDialog:init(game_state)
        else
            self.select_mode_idx = self.select_mode_idx + 1
        end
        select_mode = SELECT_MODES[self.select_mode_idx]
    end

    if self.lattice_state == LTC_STATE_SELECTING then
        if select_mode == "x" then
            if key == "left" then
                self.selected[1] = self.selected[1] - 1
                self.blink_cursor_on = true
            elseif key == "right" then
                self.selected[1] = self.selected[1] + 1
                self.blink_cursor_on = true
            end
        elseif select_mode == "y" then
            if key == "up" then
                self.selected[2] = self.selected[2] - 1
                self.blink_cursor_on = true
            elseif key == "down" then
                self.selected[2] = self.selected[2] + 1
                self.blink_cursor_on = true
            end
        elseif select_mode == "z" then
            if key == "up" then
                self.selected[3] = self.selected[3] - 1
                self.blink_cursor_on = true
            elseif key == "down" then
                self.selected[3] = self.selected[3] + 1
                self.blink_cursor_on = true
            end
        end

        self:_ensure_grid_size_selected(1)
        self:_ensure_grid_size_selected(2)
        self:_ensure_grid_size_selected(3)
    end

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

        if self.lattice_state == LTC_STATE_SELECTED then
            self.connected_window:update(game_state)
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
    if connected and self.blink_cursor_on then
        if select_mode == "y" and (z - 1) == self.selected[2] then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "z" then
            if (y - 1) == self.selected[3] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif (z - 1) == self.selected[2] then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
    end
    love.graphics.line(
        ((x - z) * LATTICE_BLOCK_WIDTH) + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
        (x - z + 1) * LATTICE_BLOCK_WIDTH + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING))
    renderer:set_color("white")
    love.graphics.setLineWidth(1)

    -- Left
    if connected and self.blink_cursor_on then
        if select_mode == "x" and (x - 1) == self.selected[1] then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "y" and (x - 1) == self.selected[1] then
            renderer:set_color("yellow")
            love.graphics.setLineWidth(3)
        elseif select_mode == "z" then
            if (y - 1) == self.selected[3] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif (x - 1) == self.selected[1] then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
    end
    love.graphics.line(
        (x - z - 1) * LATTICE_BLOCK_WIDTH - LATTICE_X_TWEAK - x_move,
        (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
        ((x - z) * LATTICE_BLOCK_WIDTH) + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING))
    renderer:set_color("white")
    love.graphics.setLineWidth(1)

    -- Right
    if connected and self.blink_cursor_on then
        if select_mode == "x" and x == self.selected[1] then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "y" and x == self.selected[1] then
            renderer:set_color("yellow")
            love.graphics.setLineWidth(3)
        elseif select_mode == "z" then
            if (y - 1) == self.selected[3] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif x == self.selected[1] then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
    end
    love.graphics.line(
        ((x - z) * LATTICE_BLOCK_WIDTH) - LATTICE_X_TWEAK - x_move,
        (y + z + 1) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING),
        (x - z + 1) * LATTICE_BLOCK_WIDTH + LATTICE_X_TWEAK - x_move,
        (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING))
    renderer:set_color("white")
    love.graphics.setLineWidth(1)

    -- Bottom
    if connected and self.blink_cursor_on then
        if select_mode == "y" and z == self.selected[2] then
            renderer:set_color("red")
            love.graphics.setLineWidth(3)
        elseif select_mode == "z" then
            if (y - 1) == self.selected[3] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif z == self.selected[2] then
                renderer:set_color("yellow")
                love.graphics.setLineWidth(3)
            end
        end
    end
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
            elseif select_mode == "y" then
                if (z - 1) == self.selected[2] then
                    renderer:set_color("red")
                    love.graphics.setLineWidth(3)
                elseif x == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
            elseif select_mode == "z" then
                if (z - 1) == self.selected[2] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                elseif x == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
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
            elseif select_mode == "y" then
                if z == self.selected[2] then
                    renderer:set_color("red")
                    love.graphics.setLineWidth(3)
                elseif (x - 1) == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
            elseif select_mode == "z" then
                if z == self.selected[2] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                elseif (x - 1) == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
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
            elseif select_mode == "y" then
                if z == self.selected[2] then
                    renderer:set_color("red")
                    love.graphics.setLineWidth(3)
                elseif x == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
            elseif select_mode == "z" then
                if z == self.selected[2] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                elseif x == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
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
        if connected and self.blink_cursor_on then
            if select_mode == "x" and (x - 1) == self.selected[1] then
                renderer:set_color("red")
                love.graphics.setLineWidth(3)
            elseif select_mode == "y" then
                if (z - 1) == self.selected[2] then
                    renderer:set_color("red")
                    love.graphics.setLineWidth(3)
                elseif (x - 1) == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
            elseif select_mode == "z" then
                if (z - 1) == self.selected[2] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                elseif (x - 1) == self.selected[1] then
                    renderer:set_color("yellow")
                    love.graphics.setLineWidth(3)
                end
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
    local width = renderer:getDrawAreaWidth()
    local height = renderer:getDrawAreaHeight()

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
    --local connected = player_info:get_lattice_intensity(player_info.overmap_x, player_info.overmap_y) < (constants.LATTICE_MINUMUM_INTENSITY + 200)
    local connected = true
    if connected then
        renderer:set_color("green")
        renderer:draw_string("CONNECTED", 3, 5)
    else
        renderer:set_color("red")
        renderer:draw_string("DISCONNECTED", 3, 5)
    end

    self:_render_lattice(renderer, game_state, connected)
    love.graphics.origin()

    if self.lattice_state == LTC_STATE_SELECTED then
        self.connected_window:render(renderer, game_state)
    end
end

return LatticeState
