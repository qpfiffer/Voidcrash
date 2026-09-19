local Screen = require("src/Screen")
local LeftWipeState = Screen.extend()

local constants = require("src/Constants")

-- In traumae glyphs, which are a different size from the map's: not constants.MAP_*.
local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

function LeftWipeState:init(next_state)
    local this = {
        next_state = next_state,
        char_update_constant = 0,
        screen_state = {}
    }
    setmetatable(this, self)

    return this
end

function LeftWipeState:key_pressed(game_state, key)
    game_state:push_state(self.next_state)
end

-- The wipe stutters: each advance waits a random 1-3 ticks.
local function _random_wipe_period()
    return math.random(TICKS_ADVANCE_MIN, TICKS_ADVANCE_MAX) * constants.WIPE_TICK
end

function LeftWipeState:on_start(game_state)
    self.timers:every(_random_wipe_period, function() self:_advance_wipe(game_state) end)
end

function LeftWipeState:on_exit(game_state)
    self.timers:cancel_all()
end

function LeftWipeState:_advance_wipe(game_state)
    self.char_update_constant = self.char_update_constant + 1

    local max_total_added = 3
    local total_added_so_far = 0
    local reached_bottom = false

    for x=1, MAP_X_MAX + 1 do
        for y=1, MAP_Y_MAX + 1 do
            if self.screen_state[x] == nil then
                self.screen_state[x] = {}
            end

            local cur_char = self.screen_state[x][y]
            local should_add = love.math.random()
            if cur_char == 1 then
                local which_char = love.math.random(32)
                local which_color = love.math.random(4)
                self.screen_state[x][y] = {which_char, which_color}
            elseif cur_char == nil and total_added_so_far < max_total_added and should_add > 0.8 then
                self.screen_state[x][y] = 1
                if y >= MAP_Y_MAX then
                    reached_bottom = true
                end

                -- Stop adding chars to this line. Break out of this Y column.
                break
            end

            if y > #self.screen_state[x] then
                break
            end
        end
    end

    if reached_bottom then
        game_state:push_state(self.next_state)
    end
end

function LeftWipeState:render(renderer)
    local row_offset = 0
    local column_offset = 0

    local color_list = {
        "red",
        "gray",
        "grayest",
        "white"
    }

    for x=1, #self.screen_state do
        for y=1, #self.screen_state[x] do
            local ref = self.screen_state[x][y]
            if ref ~= nil then
                -- local current_char = current_char_list[1 + math.fmod(self.char_update_constant, #current_char_list)]
                if ref == 1 then
                    renderer:set_color("grayest")
                    renderer:draw_traumae_string("" .. ref, y, x + row_offset)
                else
                    local char = ref[1]
                    local color = ref[2]
                    renderer:set_color(color_list[color])
                    renderer:draw_traumae_glyph(char, y, x + row_offset)
                end
            end
        end
    end
end

return LeftWipeState
