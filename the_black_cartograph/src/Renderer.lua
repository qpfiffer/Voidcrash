local Renderer = {}
Renderer.__index = Renderer

scale = love.window.getDPIScale()

SKULL_FONT_WIDTH = 12
SKULL_FONT_HEIGHT = 16
KERN_OFFSET = 3

PADDING_X = 0
PADDING_Y = 0


SKULL_PALLETTE = {
    ["white"] = {1,1,1},
    ["gray"] = {0.66, 0.66, 0.66},
    ["grayer"] = {0.33, 0.33, 0.33},
    ["grayest"] = {0.137, 0.137, 0.137},
    ["red"] = {1,0.32,0.32},
    ["blood"] = {0.66,1,1},

    ["green"] = {0.32,1,0.32}
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
        skull_font = love.graphics.newImage("assets/font.png"),

        canvas = nil,
        shader = nil
    }
    setmetatable(this, self)

    local str = love.filesystem.read("assets/CRT-moonshine.frag")
    this.canvas = love.graphics.newCanvas()
    this.shader = love.graphics.newShader(str)

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
            (cur_iter * (SKULL_FONT_WIDTH - KERN_OFFSET) + PADDING_X) * scale,
            (roffset * SKULL_FONT_WIDTH + (row * 3) + PADDING_Y) * scale,
            0, scale, scale, 0, 0)
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
    local cc = SKULL_PALLETTE[color_name]
    self.current_color = cc
    love.graphics.setColor(cc[1], cc[2], cc[3], 255)
end

function Renderer:render(game_state)
    love.graphics.clear({0, 0, 0})
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear({0, 0, 0})

    local r, g, b, a = love.graphics.getColor()
    game_state:render_current_state(self)
    love.graphics.setColor(r, g, b, a)

    love.graphics.setCanvas()
    love.graphics.setShader(self.shader)
    --shader:send("inputSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    --shader:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    love.graphics.draw(self.canvas)
    love.graphics.setShader()
end

return Renderer
