local utf8 = require("utf8")
skull_font_width = 12
skull_font_height = 16
kern_offset = 3
skull_pallette = {
    ["white"] = {255,255,255},
    ["gray"] = {170,170,170},
    ["grayer"] = {85,85,85},
    ["red"] = {255,82,82},
    ["blood"] = {170,0,0}
}

window_width = 640
window_height = 480

padding_x = 0
padding_y = 0

function _skull_quad(row, column)
    return love.graphics.newQuad(column * skull_font_width, row * skull_font_height + (3 * row),
        skull_font_width, skull_font_height, skull_font:getWidth(), skull_font:getHeight())
end

function _row_and_column_for_char(char)
    -- Everything greater than 20 is ASCII
    local byte = string.byte(char)
    local row = math.floor(byte / 32)
    local column = byte % 32
    return {row, column}
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
    if key == "pagedown" then
        current_offset = current_offset + (16 * max_rows)
    end
    if key == "pageup" then
        current_offset = current_offset - (16 * max_rows)
        if current_offset < 0 then
            current_offset = 0
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
        local row_and_col = _row_and_column_for_char(c)
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
        numbers[i] = str:sub(i, i)
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
    accum = accum + draw_string("1x", 0, accum)
end

function draw_map()
    map_data = { {0,0,0,0,3,3,5,6},
                 {0,0,0,3,3,3,4,4},
               }
end

function love.draw()
    draw_breadcrumbs()
    draw_map()
end
