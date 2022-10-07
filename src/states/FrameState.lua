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

        frame_selected_idx = 1,
        blink_cursor_on = false,
        frame_count = 0,
    }
    setmetatable(this, self)

    return this
end

function FrameState:key_pressed(game_state, key)
    if key == "up" then
        self.frame_selected_idx = self.frame_selected_idx - 1
    elseif key == "down" then
        self.frame_selected_idx = self.frame_selected_idx + 1
    end

    self.blink_cursor_on = true

    local frames = game_state.player_info.hull:get_cargo_items_of_type(ObjectType.FRAME)
    local deployed_frames = game_state.player_info:get_world_objects_of_type(ObjectType.FRAME)
    local all_frames_in_tables = {frames, deployed_frames}

    local frame_count = 0
    for i=1, #all_frames_in_tables do
        local table = all_frames_in_tables[i]
        for j=1, #table do
            frame_count = frame_count + 1
        end
    end

    if self.frame_selected_idx > frame_count then
        self.frame_selected_idx = 1
    elseif self.frame_selected_idx < 1 then
        self.frame_selected_idx = frame_count
    end
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

function FrameState:_draw_left_pane(renderer, game_state, all_frames_in_tables)
    local x = 1
    local y = 1
    local w = 15
    local h = constants.MAP_Y_MAX - 1

    renderer:render_window(x, y, w - 4, h, "black", "white")

    local row = 1
    for i=1, #all_frames_in_tables do
        local table = all_frames_in_tables[i]
        for j=1, #table do
            local frame = table[j]
            local accum = 2

            local selected_str = "  "
            if row == self.frame_selected_idx then
                selected_str = "* "
            end

            row = row + 1

            if frame:get_deployed() then
                renderer:set_color("white")
            else
                renderer:set_color("gray")
            end

            accum = accum + renderer:draw_string(selected_str .. frame:get_name(), row, accum)
        end
    end
end

function FrameState:_draw_selected_frame(renderer, game_state, all_frames_in_tables)
    local x = 16
    local y = 1
    local w = constants.MAP_X_MAX - 15
    local h = constants.MAP_Y_MAX - 1

    renderer:render_window(x, y, w - 4, h, "black", "white")

    local idx = self.frame_selected_idx
    local frame = nil
    for i=1, #all_frames_in_tables do
        local table = all_frames_in_tables[i]
        if idx <= #table then
            frame = table[idx]
            break
        else
            idx = idx - #table
        end
    end

    if not frame then
        return
    end

    local accum = 1 + x
    local row = 1
    row = row + 1

    renderer:set_color("gray")
    accum = accum + renderer:draw_string(" " .. tostring(frame:get_name()) .. ": ", row, accum)
    if frame:get_deployed() then
        renderer:set_color("white")
        accum = accum + renderer:draw_string(frame:get_x() .. ", " .. frame:get_y(), row, accum)
    else
        renderer:set_color("gray")
        accum = accum + renderer:draw_string("In Hold", row, accum)
    end

    row = row + 2
    accum = 1 + x

    renderer:set_color("white")
    accum = accum + renderer:draw_string(" Cargo: ", row, accum)

    renderer:set_color("gray")
    local cargo = frame:get_cargo()
    if #cargo > 0 then
        accum = 1 + x
        for i=1, #cargo do
            local cargo_item = frame:get_cargo()[i]
            row = row + 1
            accum = accum + renderer:draw_string("  * " .. cargo_item:get_name(), row, accum)
        end
    else
        accum = accum + renderer:draw_string("N/A", row, accum)
    end
end

function FrameState:render(renderer, game_state)
    local frames = game_state.player_info.hull:get_cargo_items_of_type(ObjectType.FRAME)
    local deployed_frames = game_state.player_info:get_world_objects_of_type(ObjectType.FRAME)
    local all_frames_in_tables = {frames, deployed_frames}

    self:_draw_left_pane(renderer, game_state, all_frames_in_tables)
    self:_draw_selected_frame(renderer, game_state, all_frames_in_tables)
end

return FrameState
