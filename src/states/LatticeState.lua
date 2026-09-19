local Screen = require("src/Screen")
local LatticeState = Screen.extend()

local SleeperDialog = require("src/ui/SleeperDialog")

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
        blink_cursor_on = true, -- Refreshed from the shared clock blink on every render.

        selected = {1, 1, 1},
        select_mode_idx = 1,

        lattice_state = LTC_STATE_SELECTING,
        connected_window = nil,
    }
    setmetatable(this, self)

    return this
end

function LatticeState:get_name()
    return "LAT"
end

function LatticeState:uses_blink()
    return true
end

function LatticeState:_ensure_grid_size_selected(idx)
    if self.selected[idx] > LATTICE_GRID_SIZE then
        self.selected[idx] = 0
    elseif self.selected[idx] < 0 then
        self.selected[idx] = LATTICE_GRID_SIZE
    end
end

-- Hang up on the sleeper, then step back through z, y, x.
function LatticeState:on_escape(game_state)
    if self.lattice_state == LTC_STATE_SELECTED then
        self.lattice_state = LTC_STATE_SELECTING
        return true
    elseif self.select_mode_idx > 1 then
        self.select_mode_idx = self.select_mode_idx - 1
        return true
    end
    return false
end

function LatticeState:key_pressed(game_state, key)
    local select_mode = SELECT_MODES[self.select_mode_idx]

    if key == "return" then
        if select_mode == "z" then
            self.lattice_state = LTC_STATE_SELECTED
            if not self.connected_window then
                self.connected_window = SleeperDialog:init(game_state, function()
                    -- It keeps typing while we're on another tab; only redraw if it can be seen.
                    if game_state:get_current_state() == self then
                        game_state:invalidate()
                    end
                end)
            end
        else
            self.select_mode_idx = self.select_mode_idx + 1
        end
        select_mode = SELECT_MODES[self.select_mode_idx]
    end

    if self.lattice_state == LTC_STATE_SELECTING then
        if select_mode == "x" then
            if key == "left" then
                self.selected[1] = self.selected[1] - 1
            elseif key == "right" then
                self.selected[1] = self.selected[1] + 1
            end
        elseif select_mode == "y" then
            if key == "up" then
                self.selected[2] = self.selected[2] - 1
            elseif key == "down" then
                self.selected[2] = self.selected[2] + 1
            end
        elseif select_mode == "z" then
            if key == "up" then
                self.selected[3] = self.selected[3] - 1
            elseif key == "down" then
                self.selected[3] = self.selected[3] + 1
            end
        end

        self:_ensure_grid_size_selected(1)
        self:_ensure_grid_size_selected(2)
        self:_ensure_grid_size_selected(3)
    end

    if self.select_mode_idx > #SELECT_MODES then
        self.select_mode_idx = 1
    elseif self.select_mode_idx <= 0 then
        self.select_mode_idx = #SELECT_MODES
    end
end

-- Which highlight (if any) a lattice edge gets. `xs` and `zs` are the x and z
-- grid lines the edge lies on (nil if it doesn't lie on one), `level` is the
-- horizontal layer it belongs to (nil for the verticals between layers).
--   x mode: the chosen x line is red.
--   y mode: the chosen z line is red, the already chosen x line yellow.
--   z mode: the chosen layer is red, the already chosen lines yellow.
function LatticeState:_edge_highlight(xs, zs, level)
    local select_mode = SELECT_MODES[self.select_mode_idx]
    local on_x = xs ~= nil and xs == self.selected[1]
    local on_z = zs ~= nil and zs == self.selected[2]

    if select_mode == "x" then
        if on_x then return "red" end
    elseif select_mode == "y" then
        if on_z then return "red" end
        if on_x then return "yellow" end
    elseif select_mode == "z" then
        if level ~= nil and level == self.selected[3] then return "red" end
        if on_z or on_x then return "yellow" end
    end
    return nil
end

function LatticeState:_draw_edge(renderer, highlight, x1, y1, x2, y2)
    if highlight then
        renderer:set_color(highlight)
        love.graphics.setLineWidth(3)
    end
    love.graphics.line(x1, y1, x2, y2)
    if highlight then
        renderer:set_color("white")
        love.graphics.setLineWidth(1)
    end
end

-- One cell of the lattice: a parallelogram on layer y, plus (except on the
-- bottom layer) a vertical dropping from each of its corners to the layer below.
function LatticeState:_render_lattice_cell(renderer, connected, x, y, z, x_move)
    local lit = connected and self.blink_cursor_on
    local function highlight(xs, zs, level)
        return lit and self:_edge_highlight(xs, zs, level) or nil
    end

    -- The corners: far (n) and near (s) edge, left (1) and right (2).
    local far_y = (y + z) * LATTICE_BLOCK_HEIGHT + (y * LATTICE_Y_PADDING)
    local near_y = far_y + LATTICE_BLOCK_HEIGHT
    local n1_x = ((x - z) * LATTICE_BLOCK_WIDTH) + LATTICE_X_TWEAK - x_move
    local n2_x = n1_x + LATTICE_BLOCK_WIDTH
    local s1_x = ((x - z - 1) * LATTICE_BLOCK_WIDTH) - LATTICE_X_TWEAK - x_move
    local s2_x = s1_x + LATTICE_BLOCK_WIDTH

    local level = y - 1
    self:_draw_edge(renderer, highlight(nil, z - 1, level), n1_x, far_y, n2_x, far_y)     -- Top
    self:_draw_edge(renderer, highlight(x - 1, nil, level), s1_x, near_y, n1_x, far_y)    -- Left
    self:_draw_edge(renderer, highlight(x, nil, level), s2_x, near_y, n2_x, far_y)        -- Right
    self:_draw_edge(renderer, highlight(nil, z, level), s1_x, near_y, s2_x, near_y)       -- Bottom

    if y ~= LATTICE_GRID_SIZE + 1 then
        local drop = 2 * LATTICE_Y_PADDING
        self:_draw_edge(renderer, highlight(x, z - 1), n2_x, far_y, n2_x, far_y + drop)
        self:_draw_edge(renderer, highlight(x - 1, z), s1_x, near_y, s1_x, near_y + drop)
        self:_draw_edge(renderer, highlight(x, z), s2_x, near_y, s2_x, near_y + drop)
        self:_draw_edge(renderer, highlight(x - 1, z - 1), n1_x, far_y, n1_x, far_y + drop)
    end
end

function LatticeState:_render_lattice(renderer, game_state, connected)
    local width = renderer:getDrawAreaWidth()
    local height = renderer:getDrawAreaHeight()

    renderer:set_color("white")
    renderer:flush() -- Queued text must land before the transform changes.
    love.graphics.translate(width/2, height/16 - 225)

    for x = 1, LATTICE_GRID_SIZE do
        for y = 1, LATTICE_GRID_SIZE + 1 do
            for z = 1, LATTICE_GRID_SIZE do
                local x_move = (LATTICE_X_TWEAK * 2) * (z - 1)

                self:_render_lattice_cell(renderer, connected, x, y, z, x_move)
            end
        end
    end
end

function LatticeState:render(renderer, game_state)
    self.blink_cursor_on = game_state.clock:blink_on()

    renderer:draw_traumae_string("LATTICE CONN", 1, 1)
    renderer:draw_string("Lattice Sleeper Conn.", 2, 1)
    renderer:draw_string("CONN: ", 3, 1)

    local connected = true
    if connected then
        renderer:set_color("green")
        renderer:draw_string("CONNECTED", 3, 6)
    else
        renderer:set_color("red")
        renderer:draw_string("DISCONNECTED", 3, 6)
    end

    self:_render_lattice(renderer, game_state, connected)
    love.graphics.origin()

    if self.lattice_state == LTC_STATE_SELECTED then
        self.connected_window:render(renderer, game_state)
    end
end

return LatticeState
