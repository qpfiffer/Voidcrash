local dbg = require("debugger")
local InitialState = {}
InitialState.__index = InitialState

local TICKER_RATE = 0.1

-- Text to display, row, and then amount of time to wait before the next one.
local fancy_text = {
    {"Init...", 0, 3, "gray"},
    {"Outboard Sensors: ", 1, 1, "gray"},
    {"[online]", 1, 1, "green"},
    {"Next", 2, 1, "gray"}
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

function InitialState:update(dt)
    self.dtotal = self.dtotal + dt   -- we add the time passed since the last update, probably a very small number like 0.01
    if self.dtotal >= TICKER_RATE then
        self.dtotal = self.dtotal - TICKER_RATE   -- reduce our timer by a second, but don't discard the change... what if our framerate is 2/3 of a second?
        self.current_text_idx = self.current_text_idx + 1
        self.ticks_since_change = self.ticks_since_change + 1

        local current_text_item = fancy_text[self.current_text_item_idx]
        if self.ticks_since_change >= current_text_item[3] and self.current_text_idx > string.len(current_text_item[1]) then
            self.ticks_since_change = 0
            self.current_text_idx = 0
            self.current_text_item_idx = self.current_text_item_idx + 1
        end
    end
end

function InitialState:render(renderer)
    local row_accum = 0
    local column_accum = 0
    local current_text_item = fancy_text[self.current_text_item_idx]

    for i=1, self.current_text_item_idx do
        local current_text_item = fancy_text[i]
        local current_color = current_text_item[4]
        renderer:set_color(current_color)
        renderer:draw_string(string.sub(current_text_item[1], i, self.current_text_idx), current_text_item[2], column_accum)
    end
end

return InitialState
