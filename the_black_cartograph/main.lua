local utf8 = require("utf8")

local GameState = require("src/GameState")
local InitialState = require("src/states/InitialState")
local Renderer = require("src/Renderer")

scale = 2 -- love.window.getDPIScale()
window_width = 640 * scale
window_height = 480 * scale

current_x_offset = 0
current_y_offset = 0

zoom_level = 1

local game_state = nil
local renderer = nil

function love.load(arg)
    love.mouse.setVisible(false)
    love.window.setTitle("black_cartograph.exe")
    love.window.setMode(window_width, window_height, {resizable=false, vsync=false})

    local initial_state = InitialState:init()
    game_state = GameState:init(initial_state)
    renderer = Renderer:init()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if key == "left" then
        current_x_offset = current_x_offset - 1
    end
    if key == "right" then
        current_x_offset = current_x_offset + 1
    end
    if key == "up" then
        current_y_offset = current_y_offset - 1
    end
    if key == "down" then
        current_y_offset = current_y_offset + 1
    end

    if key == "pageup" then
        zoom_level = zoom_level - 1
    end
    if key == "pagedown" then
        zoom_level = zoom_level + 1
    end

    if zoom_level <= 0 then
        zoom_level = 1
    end
end

function love.textinput(key)
end

function love.update(dt)
    game_state:update_current_state(dt)
end

function draw_breadcrumbs()
    -- Vector
    local accum = 0
    set_color("gray")
    accum = accum + draw_string("V: ", 0, accum)
    set_color("white")
    accum = accum + draw_string("\0 ", 0, accum)

    -- Distance
    set_color("gray")
    accum = accum + draw_string("D: ", 0, accum)
    set_color("white")
    accum = accum + draw_string("0 ", 0, accum)

    -- Zoom level
    set_color("gray")
    accum = accum + draw_string("Z: ", 0, accum)
    set_color("red")
    accum = accum + draw_string(tostring(zoom_level), 0, accum)
end

step = 0
function draw_map()
    local row_offset = 1
    local column_offset = 6
    local multiplier = 100
    step = step + 0.25
    for x=0,68 do
        for y=0,28 do
            local raw_noise_val = love.math.noise(
                (zoom_level * 0.02) * (x + current_x_offset),
                (zoom_level * 0.02) * (y + current_y_offset),
                (step % 1000) * 0.1)
            local noise_val = raw_noise_val * 1000

            if noise_val < 250 then
                set_color("grayest")
            elseif noise_val < 500 then
                set_color("grayer")
            elseif noise_val < 750 then
                set_color("gray")
            else
                set_color("white")
            end
            --if math.floor(noise_val) % 10 == 0 then
                draw_raw_numbers({178}, y + 1, x + row_offset)
            --end
        end
    end
end

function love.draw()
    game_state:render_current_state(renderer)
    -- draw_breadcrumbs()
    -- draw_map()
end
