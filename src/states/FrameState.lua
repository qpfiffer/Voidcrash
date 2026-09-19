local Screen = require("src/Screen")
local FrameState = Screen.extend()

local constants = require("src/Constants")
local containment = require("src/ecs/containment")

function FrameState:init()
    local this = {
        frame_selected_idx = 1,
    }
    setmetatable(this, self)

    return this
end

function FrameState:get_name()
    return "FRM"
end

-- Every frame, in the hold or out in the world, in the order they were built.
-- An entity keeps its id wherever it goes, so the list doesn't shuffle when a
-- frame is dispatched or comes home.
local function _frames(game_state)
    return game_state.world:query("Frame")
end

function FrameState:key_pressed(game_state, key)
    if key == "up" then
        self.frame_selected_idx = self.frame_selected_idx - 1
    elseif key == "down" then
        self.frame_selected_idx = self.frame_selected_idx + 1
    end

    local frame_count = #_frames(game_state)
    if self.frame_selected_idx > frame_count then
        self.frame_selected_idx = 1
    elseif self.frame_selected_idx < 1 then
        self.frame_selected_idx = frame_count
    end
end

function FrameState:_draw_left_pane(renderer, game_state, frames)
    local world = game_state.world
    local x = 1
    local y = 1
    local w = 15
    local h = constants.MAP_Y_MAX - 1

    renderer:render_window(x, y, w - 4, h, "black", "white")

    for i=1, #frames do
        local frame = frames[i]
        local selected_str = "  "
        if i == self.frame_selected_idx then
            selected_str = "* "
        end

        -- Out in the world is bright, in the hold is dim.
        if world:has(frame, "Position") then
            renderer:set_color("white")
        else
            renderer:set_color("gray")
        end

        renderer:draw_string(selected_str .. world:get(frame, "Named").name, i + 1, 2)
    end
end

function FrameState:_draw_selected_frame(renderer, game_state, frames)
    local world = game_state.world
    local x = 16
    local y = 1
    local w = constants.MAP_X_MAX - 15
    local h = constants.MAP_Y_MAX - 1

    renderer:render_window(x, y, w - 4, h, "black", "white")

    local frame = frames[self.frame_selected_idx]
    if not frame then
        return
    end

    local accum = 1 + x
    local row = 2

    renderer:set_color("gray")
    accum = accum + renderer:draw_string(" " .. world:get(frame, "Named").name .. ": ", row, accum)
    local position = world:get(frame, "Position")
    if position then
        renderer:set_color("white")
        accum = accum + renderer:draw_string(position.x .. ", " .. position.y, row, accum)
    else
        renderer:set_color("gray")
        accum = accum + renderer:draw_string("In Hold", row, accum)
    end

    row = row + 2
    accum = 1 + x

    renderer:set_color("white")
    accum = accum + renderer:draw_string(" Cargo: ", row, accum)

    renderer:set_color("gray")
    local cargo = containment.contents(world, frame)
    if #cargo > 0 then
        for i=1, #cargo do
            row = row + 1
            renderer:draw_string("  * " .. world:get(cargo[i], "Named").name, row, 1 + x)
        end
    else
        renderer:draw_string("N/A", row, accum)
    end
end

function FrameState:render(renderer, game_state)
    local frames = _frames(game_state)

    self:_draw_left_pane(renderer, game_state, frames)
    self:_draw_selected_frame(renderer, game_state, frames)
end

return FrameState
