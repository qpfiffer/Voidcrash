local dbg = require("debugger")
local SleeperDialog = {}
SleeperDialog.__index = SleeperDialog

local constants = require("src/Constants")

local BLINK_TICK_COUNT = 20

function SleeperDialog:_new_item(text)
    -- Don't move this function, it needs to be up here for init() to work.
    local split_text = {}

    for w in text:gmatch("%S+") do
        local new_split_text_item = {
            word = w,
            color = "white",
        }

        local r = math.random(0, 100)
        if r < 35 then
            new_split_text_item.color = "gray"
        elseif r < 65 then
            new_split_text_item.color = "red"
        elseif r > 90 then
            new_split_text_item.color = "grayer"
        end
        table.insert(split_text, new_split_text_item)
    end

    return {
        original_text = text,
        split_text = split_text,
        current_text_idx = 0,
        highlighted_indexes = highlighted_indexes,
    }
end


function SleeperDialog:init(game_state)
    local this = {
        dtotal = 0,
        ticks_advanced = 3,

        items = {},
        items_to_render = {},

        current_text_item_idx = 1,
        ticker = 1,
    }
    setmetatable(this, self)

    this.items_to_render = {
        self:_new_item("the harvest moon is"),
        self:_new_item("good for black tides"),
        self:_new_item("and a dead wind blows"),
        self:_new_item("jjj kel iw owiei lkd"),
        self:_new_item("how do we keep it sane"),
        self:_new_item("asd def fhi jkle ojk lieo lsi"),
        self:_new_item("ieowk lkwe jof owkel idjf. ie"),
        self:_new_item("fke lwke jflke f"),
        self:_new_item("flwke jlfke wlkej kefifo o"),
    }

    for i=1, 15 do
        local str = ""
        for j=1, math.random(5, 30) do
            local randlowercase = " "
            if math.random(0, 100) < 50 then
                randlowercase = string.char(math.random(65, 65 + 25)):lower()
            end
            str = str .. randlowercase
        end
        table.insert(this.items_to_render, self:_new_item(str))
    end

    return this
end

function SleeperDialog:handle_keys(game_state, dt)
end

function SleeperDialog:key_pressed(game_state, key)
    --if key == "return" then
    --    self.items[self.selected_idx]["callback"](self.bonus_data)
    --elseif key == "up" then
    --    self.selected_idx = self.selected_idx - 1
    --elseif key == "down" then
    --    self.selected_idx = self.selected_idx + 1
    --end

    --if self.selected_idx > #self.items then
    --    self.selected_idx = self.first_enabled_idx
    --elseif self.selected_idx < self.first_enabled_idx then
    --    self.selected_idx = #self.items
    --end
end

function SleeperDialog:update(game_state, dt)
    if game_state:get_paused() then
        return
    end

    self.dtotal = self.dtotal + dt
    local tick_modifier = 8
    local modified_tick = constants.TICKER_RATE / tick_modifier
    if self.dtotal >= modified_tick then
        self.dtotal = self.dtotal - modified_tick
        self.ticks_advanced = self.ticks_advanced - 1

        if self.ticks_advanced > 0 then
            -- Wait til next time.
            return
        end

        --local organic_modifier = math.random(1, 5)
        --self.ticks_advanced = BLINK_TICK_COUNT - organic_modifier
        self.ticks_advanced = 2 + math.random(0, 5)

        local current_item = self.items[self.current_text_item_idx]
        if not current_item then
            if #self.items_to_render > 0 then
                local head = table.remove(self.items_to_render)
                table.insert(self.items, head)
                current_item = head
            else
                return
            end
        end

        if current_item.current_text_idx < string.len(current_item.original_text) then
            current_item.current_text_idx = current_item.current_text_idx + 1
        else
            self.current_text_item_idx = self.current_text_item_idx + 1
        end

        if self.current_text_item_idx > #self.items and #self.items_to_render == 0 then
            self.current_text_item_idx = #self.items
        end
    end
end

function SleeperDialog:render(renderer, game_state)
    local x = 5
    local y = 5
    local w = constants.MAP_X_MAX - 10
    local h = constants.MAP_Y_MAX - 8

    local fg_color = "white"
    local bg_color = "black"
    renderer:render_window(x, y, w + 2, h, bg_color, fg_color)

    local accum_initial = x - 2 -- Hand-picked "Move traumae over to the left" offset
    local row = h + 9
    local accum = accum_initial
    local items_len = #self.items
    for i=1, items_len do
        local item = self.items[items_len - i + 1]
        local rendered_letters = 0

        for j=1, #item.split_text do
            if rendered_letters == item.current_text_idx then
                break
            end

            local word_item = item.split_text[j]
            local word = word_item.word .. " "
            renderer:set_color(word_item.color)

            local remainder = item.current_text_idx - rendered_letters
            local len = 0
            if remainder > string.len(word) then len = string.len(word) else len = remainder end
            local substr = string.sub(word, 1, len)
            rendered_letters = rendered_letters + len
            accum = accum + renderer:draw_traumae_string(substr, row, accum)
        end

        --accum = accum + renderer:draw_traumae_string(" ", row, accum)

        row = row - 1
        accum = accum_initial
    end
end

return SleeperDialog
