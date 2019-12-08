local LeftWipeState = {}
LeftWipeState.__index = LeftWipeState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 28

local TICKS_ADVANCE_MIN = 5
local TICKS_ADVANCE_MAX = 15

function LeftWipeState:init(next_state)
    local this = {
        dtotal = 0,             -- Delta time total
        ticks_advanced = TICKS_ADVANCE_MAX,     -- Number of ticks left to go before update
        next_state = next_state,
        screen_state = {}
    }
    setmetatable(this, self)

    return this
end

function LeftWipeState:key_pressed(game_state, key)
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

        local max_total_added = 3
        local total_added_so_far = 0

        for x=1, MAP_X_MAX + 1 do
            for y=1, MAP_Y_MAX + 1 do
                if self.screen_state[x] == nil then
                    self.screen_state[x] = {}
                end

                local cur_char = self.screen_state[x][y]
                local should_add = love.math.random()
                if cur_char == '%' then
                    self.screen_state[x][y] = '0'
                elseif cur_char == nil and total_added_so_far < max_total_added and should_add > 0.8 then
                    self.screen_state[x][y] = '%'
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

    for x=1, #self.screen_state do
        for y=1, #self.screen_state[x] do
            local current_char = self.screen_state[x][y]
            if current_char ~= nil then
                renderer:set_color("red")
                renderer:draw_traumae_string(current_char, y, x + row_offset)
            end
        end
    end
end

return LeftWipeState
