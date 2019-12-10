local LeftWipeState = {}
LeftWipeState.__index = LeftWipeState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 35

local TICKS_ADVANCE_MIN = 1
local TICKS_ADVANCE_MAX = 3

function LeftWipeState:init(next_state)
    local this = {
        dtotal = 0,             -- Delta time total
        ticks_advanced = TICKS_ADVANCE_MAX,     -- Number of ticks left to go before update
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

function _random_tick_count()
    return math.random(TICKS_ADVANCE_MIN, TICKS_ADVANCE_MAX)
end

function LeftWipeState:update(game_state, dt)
    self.dtotal = self.dtotal + dt
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE
        self.ticks_advanced = self.ticks_advanced - 1

        if self.ticks_advanced > 0 then
            -- Wait til next time.
            return
        end

        -- Reset the counter.
        self.ticks_advanced = _random_tick_count()
        self.char_update_constant = self.char_update_constant + 1

        local max_total_added = 3
        local total_added_so_far = 0

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
                        game_state:push_state(self.next_state)
                    end

                    -- Stop adding chars to this line. Break out of this Y column.
                    break
                end

                if y > #self.screen_state[x] then
                    break
                end
            end
        end
    end
end

function LeftWipeState:render(renderer)
    local row_offset = 0
    local column_offset = 0

    local color_list = {
        "cyan",
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
                    renderer:_draw_raw_numbers(renderer.traumae_font, {char}, y, x + row_offset)
                end
            end
        end
    end
end

return LeftWipeState
