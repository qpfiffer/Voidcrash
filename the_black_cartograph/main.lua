local utf8 = require("utf8")

local GameState = require("src/GameState")
local InitialState = require("src/states/InitialState")
local Renderer = require("src/Renderer")

-- Constants
scale = 2 -- love.window.getDPIScale()
window_width = 640 * scale
window_height = 480 * scale

-- Game internals
local game_state = nil
local renderer = nil

-- Shader stuff
local canvas = nil
local shader = nil

function love.load(arg)
    love.mouse.setVisible(false)
    love.window.setTitle("black_cartograph.exe")
    love.window.setMode(window_width, window_height, {resizable=false, vsync=false})

    canvas = love.graphics.newCanvas()
    local str = love.filesystem.read("assets/CRT-moonshine.frag")
    shader = love.graphics.newShader(str)
    shader:send("inputSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    shader:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})

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

function love.draw()
    love.graphics.setCanvas(canvas)

    game_state:render_current_state(renderer)

    love.graphics.setCanvas()
    love.graphics.setShader(shader)
    shader:send('tex0', tex)
    love.graphics.draw(canvas)
    love.graphics.setShader()
end
