local Renderer = {}
local Utils = require("src/Utils")
Renderer.__index = Renderer

local SKULL_FONT_WIDTH = 12
local SKULL_FONT_HEIGHT = 16
local SKULL_FONT_KERN_OFFSET = 3
local SKULL_FONT_VERTICAL_SPACING = 3
local SKULL_FONT_COLUMNS = 32
local SKULL_GLYPH_COUNT = 256

local T_FONT_WIDTH = 32
local T_FONT_HEIGHT = 26
local T_FONT_KERN_OFFSET = 4
local T_FONT_VERTICAL_SPACING = 12
local T_FONT_COLUMNS = 12
local T_GLYPH_COUNT = 32

local PADDING_X = 0
local PADDING_Y = 0

-- Distance between the left edges of two neighbouring skull glyphs.
local SKULL_STRIDE = SKULL_FONT_WIDTH - SKULL_FONT_KERN_OFFSET

local SKULL_PALETTE = {
    ["white"] = {1,1,1},
    ["gray"] = {0.66, 0.66, 0.66},
    ["grayer"] = {0.33, 0.33, 0.33},
    ["grayest"] = {0.137, 0.137, 0.137},
    ["red"] = {1,0.32,0.32},
    ["blood"] = {1, 0.137, 0.137},

    ["green"] = {0.32,1,0.32},
    ["cyan"] = {0.44,0.87,0.76},

    ["yellow"] = {1.0, 1.0, 0.59},

    ["black"] = {0, 0, 0},
}

-- Quads are built once; making one per glyph per frame used to be the single
-- most expensive thing the game did.
local function _build_skull_quads(image)
    local quads = {}
    for num=0, SKULL_GLYPH_COUNT - 1 do
        local row = math.floor(num / SKULL_FONT_COLUMNS)
        local column = num % SKULL_FONT_COLUMNS
        quads[num] = love.graphics.newQuad(
            column * SKULL_FONT_WIDTH,
            row * (SKULL_FONT_HEIGHT + SKULL_FONT_VERTICAL_SPACING),
            SKULL_FONT_WIDTH,
            SKULL_FONT_HEIGHT,
            image:getWidth(),
            image:getHeight())
    end
    return quads
end

local function _build_traumae_quads(image)
    local quads = {}
    for num=0, T_GLYPH_COUNT - 1 do
        local row = math.floor(num / T_FONT_COLUMNS) -- 3 rows of twelve
        local column = num % T_FONT_COLUMNS
        quads[num] = love.graphics.newQuad(
            column * T_FONT_WIDTH,
            row * (T_FONT_HEIGHT + T_FONT_VERTICAL_SPACING),
            T_FONT_WIDTH, T_FONT_HEIGHT, image:getWidth(), image:getHeight())
    end
    return quads
end

function Renderer:init(scale, window_width, window_height)
    local aspect_ratio_width = 4
    local aspect_ratio_height = 3

    local draw_area_width = 0
    local draw_area_height = 0
    local minimum_draw = Utils.tern(window_width < window_height, window_width, window_height)
    if window_width > window_height then
        draw_area_height = minimum_draw
        draw_area_width = (minimum_draw / aspect_ratio_height) * aspect_ratio_width
    else
        -- Dunno man, untested:
        draw_area_height = (minimum_draw / aspect_ratio_height) * aspect_ratio_width
        draw_area_width = minimum_draw
    end

    local skull_font = love.graphics.newImage("assets/font.png")
    local traumae_font = love.graphics.newImage("assets/font2.png")

    local this = {
        current_color = SKULL_PALETTE["white"],
        skull_font = skull_font,
        traumae_font = traumae_font,

        skull_quads = _build_skull_quads(skull_font),
        traumae_quads = _build_traumae_quads(traumae_font),

        -- Glyphs are queued here and drawn in one call per run of same-font text.
        skull_batch = love.graphics.newSpriteBatch(skull_font, 4096, "stream"),
        traumae_batch = love.graphics.newSpriteBatch(traumae_font, 1024, "stream"),
        pending_batch = nil,

        window_rows = {}, -- Border rows for render_window, by width.

        canvas = love.graphics.newCanvas(draw_area_width, draw_area_height),
        canvas2 = love.graphics.newCanvas(draw_area_width, draw_area_height),
        canvas3 = love.graphics.newCanvas(draw_area_width, draw_area_height),
        final_canvas = love.graphics.newCanvas(draw_area_width, draw_area_height),
        crt_shader = nil,
        scanlines_shader = nil,
        scale = scale,
        window_width = window_width,
        window_height = window_height,
        draw_area_width = draw_area_width,
        draw_area_height = draw_area_height,
        anaglyph_shader = nil
    }
    setmetatable(this, self)

    -- read() also returns the size; the parens keep it out of newShader's arguments.
    this.crt_shader = love.graphics.newShader((love.filesystem.read("assets/CRT.frag")))
    this.anaglyph_shader = love.graphics.newShader((love.filesystem.read("assets/anaglyph.frag")))
    this.scanlines_shader = love.graphics.newShader((love.filesystem.read("assets/scanlines.frag")))

    -- None of the shader inputs change after startup.
    local angle, radius = 30, 1
    local dx = math.cos(angle) * radius / window_width
    local dy = math.sin(angle) * radius / window_height
    this.anaglyph_shader:send("direction", {dx, dy})
    this.scanlines_shader:send("phase", 0)

    return this
end

-- Draws everything queued so far. Anything that isn't a glyph (rectangles,
-- lines, transforms) has to call this first to keep the draw order right.
function Renderer:flush()
    local batch = self.pending_batch
    if not batch then
        return
    end

    -- The batch carries per-glyph colors; the global color would tint them.
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(batch)
    batch:clear()
    self.pending_batch = nil

    local cc = self.current_color
    love.graphics.setColor(cc[1], cc[2], cc[3], 1)
end

-- A layer is a batch of skull glyphs that survives between frames: build it
-- once with begin_layer/end_layer, then draw_layer is a single draw call.
function Renderer:new_layer()
    return {batch = love.graphics.newSpriteBatch(self.skull_font, 2048, "static")}
end

function Renderer:begin_layer(layer)
    self:flush()
    layer.batch:clear()
    self.layer_batch = layer.batch
end

function Renderer:end_layer()
    self.layer_batch = nil
end

function Renderer:draw_layer(layer)
    self:flush()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(layer.batch)
    local cc = self.current_color
    love.graphics.setColor(cc[1], cc[2], cc[3], 1)
end

function Renderer:_use_batch(batch)
    if self.layer_batch and batch == self.skull_batch then
        local cc = self.current_color
        self.layer_batch:setColor(cc[1], cc[2], cc[3], 1)
        return self.layer_batch
    end

    if self.pending_batch ~= batch then
        self:flush()
        self.pending_batch = batch
    end
    local cc = self.current_color
    batch:setColor(cc[1], cc[2], cc[3], 1)
    return batch
end

-- One skull (CP437) glyph by its number.
function Renderer:draw_glyph(num, row, col)
    local quad = self.skull_quads[num]
    if not quad then
        return
    end
    self:_use_batch(self.skull_batch):add(quad,
        (col * SKULL_STRIDE + PADDING_X) * self.scale,
        (row * SKULL_FONT_HEIGHT + PADDING_Y) * self.scale,
        0, self.scale, self.scale)
end

function Renderer:draw_traumae_glyph(num, row, col)
    local quad = self.traumae_quads[num % T_GLYPH_COUNT]
    if not quad then
        return
    end
    self:_use_batch(self.traumae_batch):add(quad,
        (col * (T_FONT_WIDTH + T_FONT_KERN_OFFSET) + PADDING_X) * self.scale/2,
        (row * T_FONT_HEIGHT + row + PADDING_Y) * self.scale/2,
        0, self.scale/2, self.scale/2)
end

function Renderer:draw_raw_numbers(array, row, col)
    for i=1, #array do
        self:draw_glyph(array[i], row, col + i - 1)
    end
    return #array
end

function Renderer:draw_string(str, row, col)
    for i=1, #str do
        self:draw_glyph(string.byte(str, i), row, col + i - 1)
    end
    return #str
end

function Renderer:draw_traumae_string(str, row, col)
    for i=1, #str do
        self:draw_traumae_glyph(string.byte(str, i), row, col + i - 1)
    end
    return #str
end

function Renderer:set_color(color_name)
    local cc = SKULL_PALETTE[color_name]
    self.current_color = cc
    -- Glyphs take their color from the batch; this is for lines and rectangles.
    love.graphics.setColor(cc[1], cc[2], cc[3], 1)
end

function Renderer:render_window_with_text(x, y, text, bg_color, fg_color)
    local w = string.len(text)
    local h = 1
    local _bg_color = bg_color or "black"
    local _fg_color = fg_color or "white"

    self:render_window(x, y, w, h, _bg_color, _fg_color)
    self:draw_string(text, y + 1, x + 2)
end

function Renderer:getDrawAreaWidth()
    return self.draw_area_width
end

function Renderer:getDrawAreaHeight()
    return self.draw_area_height
end

function Renderer:_window_rows(w)
    local rows = self.window_rows[w]
    if not rows then
        local top = {201, 205}
        local bottom = {200, 205}
        for i=1, w do
            table.insert(top, 205)
            table.insert(bottom, 205)
        end
        table.insert(top, 205)
        table.insert(top, 187)
        table.insert(bottom, 205)
        table.insert(bottom, 188)

        rows = {top = top, bottom = bottom}
        self.window_rows[w] = rows
    end
    return rows
end

-- A bordered box with w + 2 columns and h rows of interior.
function Renderer:render_window(x, y, w, h, bg_color, fg_color)
    local rows = self:_window_rows(w)
    local glyphs_wide = #rows.top

    -- Clear BG to bg_color. The box is glyphs_wide strides across, plus the
    -- part of the last glyph that sticks out past its stride.
    self:flush()
    self:set_color(bg_color)
    love.graphics.rectangle('fill',
        (x * SKULL_STRIDE + PADDING_X) * self.scale,
        (y * SKULL_FONT_HEIGHT + PADDING_Y) * self.scale,
        (glyphs_wide * SKULL_STRIDE + SKULL_FONT_KERN_OFFSET) * self.scale,
        SKULL_FONT_HEIGHT * (h + 2) * self.scale)

    -- Draw FG. The interior is already filled, so only the sides need glyphs.
    self:set_color(fg_color)
    self:draw_raw_numbers(rows.top, y, x)
    for j=1, h do
        self:draw_glyph(186, y + j, x)
        self:draw_glyph(186, y + j, x + glyphs_wide - 1)
    end
    self:draw_raw_numbers(rows.bottom, y + 1 + h, x)
end

function Renderer:render(game_state)
    -- Draw the actual stuff:
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)
    self:set_color("white")
    game_state:render_current_state(self)
    self:flush()
    love.graphics.setColor(1, 1, 1, 1)

    -- First pass. canvas2 and canvas3 are fully overwritten, no need to clear them.
    love.graphics.setCanvas(self.canvas2)
    love.graphics.setShader(self.scanlines_shader)
    love.graphics.draw(self.canvas)

    -- Second pass:
    love.graphics.setCanvas(self.canvas3)
    love.graphics.setShader(self.anaglyph_shader)
    love.graphics.draw(self.canvas2)

    -- Final pass. The CRT mask feathers the edges with alpha, so this one does need clearing.
    love.graphics.setCanvas(self.final_canvas)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(self.crt_shader)
    love.graphics.draw(self.canvas3)
    love.graphics.setShader()

    self:present_cached()
end

-- Puts the last rendered frame on screen again without redrawing any of it.
function Renderer:present_cached()
    love.graphics.setColor(1, 1, 1, 1)
    local width_offset = (self.window_width - self.draw_area_width) / 2
    local height_offset = (self.window_height - self.draw_area_height) / 2
    love.graphics.translate(width_offset, height_offset)
    love.graphics.setCanvas()
    love.graphics.draw(self.final_canvas)
    love.graphics.origin()
end

return Renderer
