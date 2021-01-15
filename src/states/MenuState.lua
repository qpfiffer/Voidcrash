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
    if cmu > #menu_items then
        self.current_menu_item = math.fmod(cmu, #menu_items)
    elseif cmu < 1 then
        self.current_menu_item = #menu_items
    end
end

function MenuState:render(renderer)
    renderer:draw_traumae_string("the harvest moon is", 8, 2)
    renderer:draw_traumae_string("good for black tides", 9, 2)
    renderer:draw_traumae_string("and a dead wind blows", 10, 2)

    for i=1, #menu_items do
        if i == self.current_menu_item then
            renderer:set_color("red")
        else
            renderer:set_color("gray")
        end
        renderer:draw_string(menu_items[i][M_TEXT], i, 0)
    end
end

return MenuState
