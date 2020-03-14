local Renderer = {}
Renderer.__index = Renderer

scale = love.window.getDPIScale()

SKULL_FONT_WIDTH = 12
SKULL_FONT_HEIGHT = 16
SKULL_FONT_KERN_OFFSET = 3
SKULL_FONT_VERTICAL_SPACING = 3

T_FONT_WIDTH = 32
T_FONT_HEIGHT = 26
T_FONT_KERN_OFFSET = 4
T_FONT_VERTICAL_SPACING = 12

PADDING_X = 0
PADDING_Y = 0

SKULL_PALLETTE = {
    ["white"] = {1,1,1},
    ["gray"] = {0.66, 0.66, 0.66},
    ["grayer"] = {0.33, 0.33, 0.33},
    ["grayest"] = {0.137, 0.137, 0.137},
    ["red"] = {1,0.32,0.32},
    ["blood"] = {1, 0.137, 0.137},

    ["green"] = {0.32,1,0.32},
    ["cyan"] = {0.44,0.87,0.76},
}

function _skull_quad(skull_font_img, row, column)
    return love.graphics.newQuad(
        column * SKULL_FONT_WIDTH,
        row * SKULL_FONT_HEIGHT + (SKULL_FONT_VERTICAL_SPACING * row),
        SKULL_FONT_WIDTH,
        SKULL_FONT_HEIGHT,
        skull_font_img:getWidth(),
        skull_font_img:getHeight())
end

function _traumae_quad(traumae_font_img, row, column)
    return love.graphics.newQuad(
        column * T_FONT_WIDTH,
        (row * T_FONT_HEIGHT) + (T_FONT_VERTICAL_SPACING * row),
        T_FONT_WIDTH, T_FONT_HEIGHT, traumae_font_img:getWidth(), traumae_font_img:getHeight())
end

function _row_and_column_for_num(num)
    -- Everything greater than 20 is ASCII
    local row = math.floor(num / 32)
    local column = num % 32
    return {row, column}
end

function _traumae_row_and_column_for_num(num)
    local max_char = math.fmod(num, 32) -- 32 total chars
    local row = math.floor(max_char / 12) -- 3 rows of twelve
    local column = math.fmod(max_char, 12)
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
        traumae_font = love.graphics.newImage("assets/font2.png"),

        canvas = love.graphics.newCanvas(),
        canvas2 = love.graphics.newCanvas(),
        canvas3 = love.graphics.newCanvas(),
        crt_shader = nil,
        scanlines_shader = nil,
        anaglyph_shader = nil
    }
    setmetatable(this, self)

    local str = love.filesystem.read("assets/CRT.frag")
    this.crt_shader = love.graphics.newShader(str)

    str = love.filesystem.read("assets/anaglyph.frag")
    this.anaglyph_shader = love.graphics.newShader(str)

    str = love.filesystem.read("assets/scanlines.frag")
    this.scanlines_shader = love.graphics.newShader(str)

    return this
end

function Renderer:_draw_raw_numbers(font, array, row, col)
    local cur_iter = col
    local roffset = row
    for i=1,#array do
        local c = array[i]
        if font == self.skull_font then
            local row_and_col = _row_and_column_for_num(c)
            local skull_quad = _skull_quad(font, row_and_col[1], row_and_col[2])
            love.graphics.draw(font, skull_quad,
                (cur_iter * (SKULL_FONT_WIDTH - SKULL_FONT_KERN_OFFSET) + PADDING_X) * scale,
                (roffset * SKULL_FONT_WIDTH + (row * 3) + PADDING_Y) * scale,
                0, scale, scale, 0, 0)
        else
            local row_and_col = _traumae_row_and_column_for_num(c)
            --print("ROW AND COL: " .. row_and_col[1] .. ", " .. row_and_col[2])
            local quad = _traumae_quad(font, row_and_col[1], row_and_col[2])
            love.graphics.draw(font, quad,
                (cur_iter * (T_FONT_WIDTH + T_FONT_KERN_OFFSET) + PADDING_X) * scale/2,
                (roffset * T_FONT_HEIGHT + row + PADDING_Y) * scale/2,
                0, scale/2, scale/2, 0, 0)
        end
        cur_iter = cur_iter + 1
    end
    return cur_iter - col
end

function Renderer:draw_raw_numbers(array, row, col)
    self:_draw_raw_numbers(self.skull_font, array, row, col)
end

function Renderer:_draw_string(font, str, row, col)
    local numbers = {}
    for i=1,#str do
        numbers[i] = string.byte(str:sub(i, i))
    end
    return self:_draw_raw_numbers(font, numbers, row, col)
end

function Renderer:draw_string(str, row, col)
    return self:_draw_string(self.skull_font, str, row, col)
end

function Renderer:draw_traumae_string(str, row, col)
    return self:_draw_string(self.traumae_font, str, row, col)
end

function Renderer:set_color(color_name)
    local cc = SKULL_PALLETTE[color_name]
    self.current_color = cc
    love.graphics.setColor(cc[1], cc[2], cc[3], 255)
end

function Renderer:render_window_with_text(x, y, text)
    local row_offset = y
    local column_offset = x

    local window_width = string.len(text) + 4
    local window_height = 3 -- Only support one line of text right now

    local top_str = {201, 205}
    local text_str = {186, 32}
    local bottom_str = {200, 205}
    for i=1, string.len(text) do
        local byte = string.byte(text:sub(i, i))
        table.insert(top_str, 205)
        table.insert(text_str, byte)
        table.insert(bottom_str, 205)
    end

    table.insert(top_str, 205)
    table.insert(top_str, 187)
    table.insert(text_str, 32)
    table.insert(text_str, 186)
    table.insert(bottom_str, 205)
    table.insert(bottom_str, 188)

    self:set_color("white")
    self:_draw_raw_numbers(self.skull_font, top_str, row_offset, column_offset)
    self:_draw_raw_numbers(self.skull_font, text_str, row_offset + 1, column_offset)
    self:_draw_raw_numbers(self.skull_font, bottom_str, row_offset + 2, column_offset)

end

function Renderer:render(game_state)
    local r, g, b, a = love.graphics.getColor()

    local arr = {self.canvas3, self.canvas2, self.canvas}
    for i=1, #arr do
        love.graphics.setCanvas(arr[i])
        love.graphics.clear({0, 0, 0})
    end

    -- Draw the actual stuff:
    game_state:render_current_state(self)
    love.graphics.setColor(r, g, b, a)

    -- First pass:
    love.graphics.setCanvas(self.canvas2)
    love.graphics.setShader(self.scanlines_shader)
    love.graphics.draw(self.canvas)

    -- Second pass:
    love.graphics.setCanvas(self.canvas3)
    love.graphics.setShader(self.anaglyph_shader)
    local angle, radius = 30, 1
    local dx = math.cos(angle) * radius / love.graphics.getWidth()
    local dy = math.sin(angle) * radius / love.graphics.getHeight()
    self.anaglyph_shader:send("direction", {dx, dy})
    love.graphics.draw(self.canvas2)

    -- Final pass
    love.graphics.setCanvas()
    love.graphics.setShader(self.crt_shader)
    love.graphics.draw(self.canvas3)
    love.graphics.setShader()
end

return Renderer
