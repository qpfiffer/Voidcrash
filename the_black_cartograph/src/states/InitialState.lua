local InitialState = {}
InitialState.__index = InitialState

local constants = require("src/Constants")

local MapState = require("src/states/MapState")

-- Text to display, row, and then amount of time to wait before the next one.
local FT_TEXT = 1
local FT_ROW = 2
local FT_WAIT = 3
local FT_COLOR = 4
local fancy_text = {
    {"Init...", 0, 1.5, "gray"},
    {"Outboard Sensors: ", 2, 1, "gray"},
    {"[online]", 2, 1, "green"},
    {"Life-support:     ", 3, 2, "gray"},
    {"[online]", 3, 1, "green"},
    {"Cargo Bays Functioning: ", 4, 2, "gray"},
    {"A ", 4, 1, "red"},
    {"B ", 4, 1, "green"},
    {"C ", 4, 1, "green"},
    {"D", 4, 1, "red"},
    {"Next..?", 6, 1, "gray"}
}

function InitialState:init()
    local this = {
        dtotal = 0,               -- Delta time total
        ticks_since_change = 0,   -- The number of ticks since we last changed text items.
        current_text_idx = 1,     -- The actual index of the character. We render one at a time.
        current_text_item_idx = 1 -- Which item in 'fancy_text' we're on.
    }
    setmetatable(this, self)

    return this
end

function InitialState:update(game_state, dt)
    self.dtotal = self.dtotal + dt   -- we add the time passed since the last update, probably a very small number like 0.01
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE   -- reduce our timer by a second, but don't discard the change... what if our framerate is 2/3 of a second?
        self.current_text_idx = self.current_text_idx + 1
        self.ticks_since_change = self.ticks_since_change + 1

        if self.current_text_item_idx > table.getn(fancy_text) then
            -- Have we reached the end of the text? Transition states.
            game_state:push_state(MapState:init())
            return
        end

        local current_text_item = fancy_text[self.current_text_item_idx]
        if self.ticks_since_change >= (current_text_item[FT_WAIT] / constants.TICKER_RATE) and self.current_text_idx > string.len(current_text_item[1]) then
            self.ticks_since_change = 0
            self.current_text_idx = 0
            self.current_text_item_idx = self.current_text_item_idx + 1
        end
    end
end

function InitialState:key_pressed(game_state, key)
end

function InitialState:render(renderer)
    local row_accum = 0
    local column_accum = 0
    local current_text_item = fancy_text[self.current_text_item_idx]
    local last_row = nil

    for i=1, table.getn(fancy_text) do
        if i > self.current_text_item_idx then
            return
        end

        local current_text_item = fancy_text[i]
        local current_color = nil
        current_text_item = fancy_text[i]
        current_color = current_text_item[FT_COLOR]

        --if self.current_text_item_idx > table.getn(fancy_text) then
        --    current_color = "red"
        --    current_text_item = {"END", 10, 0, "red"}
        --else
        --end

        renderer:set_color(current_color)
        if i < self.current_text_item_idx then
            renderer:draw_string(current_text_item[FT_TEXT], current_text_item[FT_ROW], column_accum)
            column_accum = column_accum + string.len(current_text_item[FT_TEXT])
            row_accum = current_text_item[FT_ROW]
        else
            -- Draw it in stages:
            local substr = string.sub(current_text_item[FT_TEXT], 1, self.current_text_idx)
            renderer:draw_string(substr, current_text_item[FT_ROW], column_accum)
            row_accum = current_text_item[FT_ROW]
            column_accum = column_accum + string.len(substr)
        end

        -- Reset the column counter if we're on a new row:
        if i + 1 < table.getn(fancy_text) then
            local next_row = fancy_text[i + 1]
            if next_row[FT_ROW] ~= current_text_item[FT_ROW] then
                column_accum = 0
            end
        end
    end
end

return InitialState
