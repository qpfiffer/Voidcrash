local MenuState = {}
MenuState.__index = MenuState

local constants = require("src/Constants")

local InitialState = require("src/states/InitialState")

function _start_game(game_state)
    game_state:push_state(InitialState:init())
end

function _resume_game(game_state)
    game_state:push_state(InitialState:init())
end

function _quit_game()
    love.event.quit()
end

local M_TEXT = 1
local M_FUNC = 2
local menu_items = {
    {"New Game", _start_game},
    {"Resume", _resume_game},
    {"Quit", _quit_game},
}

function MenuState:init()
    local this = {
        dtotal = 0,               -- Delta time total
        current_menu_item = 1,    -- Current menu item.
    }
    setmetatable(this, self)

    return this
end

function MenuState:update(game_state, dt)
    self.dtotal = self.dtotal + dt   -- we add the time passed since the last update, probably a very small number like 0.01
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE   -- reduce our timer by a second, but don't discard the change... what if our framerate is 2/3 of a second?
        -- Do something.
    end
end

function MenuState:key_pressed(game_state, key)
    if key == "down" then
        self.current_menu_item = self.current_menu_item + 1
    elseif key == "up" then
        self.current_menu_item = self.current_menu_item - 1
    elseif key == "return" then
        local c_menu_item = menu_items[self.current_menu_item]
        local func = c_menu_item[M_FUNC]
        func(game_state)
    end

    local cmu = self.current_menu_item
    if cmu > #menu_items or cmu < 1 then
        self.current_menu_item = math.fmod(cmu, #menu_items)
    end
end

function MenuState:render(renderer)
    for i=1, #menu_items do
        if i == self.current_menu_item then
            renderer:set_color("red")
        else
            renderer:set_color("gray")
        end
        renderer:draw_string(menu_items[i][M_TEXT], i, 0)
    end

    renderer:_draw_raw_numbers(renderer.traumae_font, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}, 7, 0)
    renderer:_draw_raw_numbers(renderer.traumae_font, {13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24}, 8, 0)
    renderer:_draw_raw_numbers(renderer.traumae_font, {25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36}, 9, 0)
end

return MenuState
