local Renderer = {}
Renderer.__index = Renderer

SKULL_FONT_WIDTH = 12
SKULL_FONT_HEIGHT = 16
KERN_OFFSET = 3

PADDING_X = 0
PADDING_Y = 0


SKULL_PALLETTE = {
    ["white"] = {255,255,255},
    ["gray"] = {170,170,170},
    ["grayer"] = {85,85,85},
    ["grayest"] = {35,35,35},
    ["red"] = {255,82,82},
    ["blood"] = {170,0,0},

    ["green"] = {82,255,82}
}

function _skull_quad(skull_font_img, row, column)
    return love.graphics.newQuad(column * SKULL_FONT_WIDTH, row * SKULL_FONT_HEIGHT + (3 * row),
        SKULL_FONT_WIDTH, SKULL_FONT_HEIGHT, skull_font_img:getWidth(), skull_font_img:getHeight())
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

function Renderer:init()
    local this = {
        current_color = SKULL_PALLETTE["white"],
        skull_font = love.graphics.newImage("assets/font.png")
    }
    setmetatable(this, self)

    return this
end

function Renderer:draw_raw_numbers(array, row, col)
    local cur_iter = col
    local roffset = row
    for i=1,#array do
        local c = array[i]
        local row_and_col = _row_and_column_for_num(c)
        local skull_quad = _skull_quad(self.skull_font, row_and_col[1], row_and_col[2])
        love.graphics.draw(self.skull_font, skull_quad,
            cur_iter * (SKULL_FONT_WIDTH - KERN_OFFSET) + PADDING_X,
            roffset * SKULL_FONT_WIDTH + (row * 3) + PADDING_Y,
            0, 1, 1, 0, 0)
        cur_iter = cur_iter + 1
    end
    return cur_iter - col
end

function Renderer:draw_string(str, row, col)
    local numbers = {}
    for i=1,#str do
        numbers[i] = string.byte(str:sub(i, i))
    end
    return self:draw_raw_numbers(numbers, row, col)
end

function Renderer:set_color(color_name)
    self.current_color = SKULL_PALLETTE[color_name]
    love.graphics.setColor(self.current_color[1], self.current_color[2], self.current_color[3], 255)
end

return Renderer
