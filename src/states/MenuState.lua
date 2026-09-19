local Screen = require("src/Screen")
local MenuState = Screen.extend()

local InitialState = require("src/states/InitialState")

local function _start_game(game_state)
    game_state:push_state(InitialState:init())
end

local function _quit_game()
    love.event.quit()
end

local M_TEXT = 1
local M_FUNC = 2
local menu_items = {
    {"New Game", _start_game},
    {"Resume", nil}, -- Nothing to resume until there are saves.
    {"Quit", _quit_game},
}

function MenuState:init()
    local this = {
        current_menu_item = 1,    -- Current menu item.
    }
    setmetatable(this, self)

    return this
end

function MenuState:key_pressed(game_state, key)
    if key == "down" then
        self.current_menu_item = self.current_menu_item + 1
    elseif key == "up" then
        self.current_menu_item = self.current_menu_item - 1
    elseif key == "return" then
        local c_menu_item = menu_items[self.current_menu_item]
        local func = c_menu_item[M_FUNC]
        if func then
            func(game_state)
        end
    end

    local cmu = self.current_menu_item
    if cmu > #menu_items then
        self.current_menu_item = math.fmod(cmu, #menu_items)
    elseif cmu < 1 then
        self.current_menu_item = #menu_items
    end
end

function MenuState:render(renderer)
    --renderer:draw_traumae_string("the harvest moon is", 8, 2)
    --renderer:draw_traumae_string("good for black tides", 9, 2)
    --renderer:draw_traumae_string("and a dead wind blows", 10, 2)

    local start = 5
    renderer:draw_string("VOIDCRASH", start, 7)
    for i=1, #menu_items do
        local pre = "  "
        if i == self.current_menu_item then
            pre = "> "
            renderer:set_color("red")
        else
            renderer:set_color("gray")
        end
        if not menu_items[i][M_FUNC] then
            renderer:set_color("grayer")
        end
        renderer:draw_string(pre .. menu_items[i][M_TEXT], i + start + 2, 5)
    end
end

return MenuState
