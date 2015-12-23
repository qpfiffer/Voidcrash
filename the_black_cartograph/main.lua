local utf8 = require("utf8")
skull_font_width = 12
skull_font_height = 16
kern_offset = 3
skull_pallette = {
    ["white"] = {255,255,255},
    ["gray"] = {170,170,170},
    ["grayer"] = {85,85,85},
    ["grayest"] = {35,35,35},
    ["red"] = {255,82,82},
    ["blood"] = {170,0,0}
}

window_width = 640
window_height = 480

padding_x = 0
padding_y = 0

current_x_offset = 0
current_y_offset = 0

zoom_level = 1

function _skull_quad(row, column)
    return love.graphics.newQuad(column * skull_font_width, row * skull_font_height + (3 * row),
        skull_font_width, skull_font_height, skull_font:getWidth(), skull_font:getHeight())
end

function _row_and_column_for_num(num)
    -- Everything greater than 20 is ASCII
    local row = math.floor(num / 32)
    local column = num % 32
    return {row, column}
end

function _row_and_column_for_char(char)
    local byte = string.byte(char)
    return _row_and_column_for_num(byte)
end

function love.load(arg)
    skull_font = love.graphics.newImage("font.png")
    love.mouse.setVisible(false)
    love.window.setTitle("black_cartograph.exe")
    love.window.setMode(window_width, window_height, {resizable=false, vsync=false})
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
        if zoom_level <= 0 then
            zoom_level = 1
        end
    end
    --if key == "backspace" then
    --    local byteoffset = utf8.offset(_build_skull_str(), -1)

    --    if byteoffset then
    --        skull_str = string.sub(skull_str, 1, byteoffset - 1)
    --    end
    --end
end

function love.textinput(key)
    --skull_str = skull_str .. key
end

function set_color(color_name)
    local current_color = skull_pallette[color_name]
    love.graphics.setColor(current_color[1], current_color[2], current_color[3], 255)
end

function draw_raw_numbers(array, row, col)
    local cur_iter = col
    local roffset = row
    for i=1,#array do
        local c = array[i]
        local row_and_col = _row_and_column_for_num(c)
        local skull_quad = _skull_quad(row_and_col[1], row_and_col[2])
        love.graphics.draw(skull_font, skull_quad,
            cur_iter * (skull_font_width - kern_offset) + padding_x,
            roffset * skull_font_width + (row * 3) + padding_y,
            0, 1, 1, 0, 0)
        cur_iter = cur_iter + 1
    end
    return cur_iter - col
end

function draw_string(str, row, col)
    local numbers = {}
    for i=1,#str do
        numbers[i] = string.byte(str:sub(i, i))
    end
    return draw_raw_numbers(numbers, row, col)
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

function draw_map()
    local row_offset = 1
    local column_offset = 6
    local multiplier = 100
    for x=0,68 do
        for y=0,28 do
            local raw_noise_val = love.math.noise((zoom_level * 0.02) * (x + current_x_offset), (zoom_level * 0.02) * (y + current_y_offset))
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
    draw_breadcrumbs()
    draw_map()
end
