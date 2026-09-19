local Screen = require("src/Screen")
local InitialState = Screen.extend()

local constants = require("src/Constants")

local GameStartState = require("src/states/GameStartState")
local LeftWipeState = require("src/states/LeftWipeState")


-- Text to display, row, and then amount of time to wait before the next one, offset
local FT_TEXT = 1
local FT_ROW = 2
local FT_WAIT = 3
local FT_COLOR = 4
local FT_OFFSET = 5
local fancy_text = {
    {"Init...", 0, 1.5, "gray", 0},

    {"Diag core internals", 2, 1, "gray", 0},
    {"- RAM OK!", 3, 1, "gray", 4},
    {"- VGATE OK!", 4, 1, "gray", 4},

    {"Diag ship internals (critical systems)", 6, 1, "gray", 0},
    {"- Cargo: ", 7, 1, "gray", 4},
    {"[pods secure]", 7, 1, "green", 4},

    {"Diag ship internals (non-critical)", 9, 1, "gray", 0},
    {"- Life Support", 10, 1, "gray", 4},

    {"AI Connection...", 12, 1, "gray", 0},
    {"- Acknowledged", 13, 1, "gray", 4},

    {"Tap current lucid state", 15, 1, "gray", 0},

    -- Glyphs here for two seconds

    {"", 11, 1, "gray", 0},
}

function InitialState:init()
    local this = {
        ticks_since_change = 0,   -- The number of ticks since we last changed text items.
        current_text_idx = 0,     -- The actual index of the character. We render one at a time.
        current_text_item_idx = 1 -- Which item in 'fancy_text' we're on.
    }
    setmetatable(this, self)

    return this
end

local function _next_state(game_state)
    game_state:push_state(LeftWipeState:init(GameStartState:init()))
end

function InitialState:on_start(game_state)
    -- One tick types one character.
    self.timers:every(1 / constants.BOOT_TEXT_CPS, function() self:_tick(game_state) end)
end

function InitialState:on_exit(game_state)
    self.timers:cancel_all()
end

function InitialState:_tick(game_state)
    self.current_text_idx = self.current_text_idx + 1
    self.ticks_since_change = self.ticks_since_change + 1

    if self.current_text_item_idx > #fancy_text then
        -- Have we reached the end of the text? Transition states.
        return _next_state(game_state)
    end

    -- A line is done once it's fully typed AND its wait (measured from its first character) is up.
    local current_text_item = fancy_text[self.current_text_item_idx]
    local wait_ticks = current_text_item[FT_WAIT] * constants.BOOT_TEXT_CPS
    if self.ticks_since_change >= wait_ticks and self.current_text_idx > string.len(current_text_item[FT_TEXT]) then
        self.ticks_since_change = 0
        self.current_text_idx = 0
        self.current_text_item_idx = self.current_text_item_idx + 1
    end
end

function InitialState:key_pressed(game_state, key)
    if key == "space" then
        return _next_state(game_state)
    end
end

function InitialState:render(renderer)
    local row_accum = 0
    local column_accum = 0
    local current_text_item = fancy_text[self.current_text_item_idx]
    local last_row = nil

    for i=1, #fancy_text do
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
        if i + 1 < #fancy_text then
            local next_row = fancy_text[i + 1]
            if next_row[FT_ROW] ~= current_text_item[FT_ROW] then
                column_accum = next_row[FT_OFFSET]
            end
        end
    end
end

return InitialState
