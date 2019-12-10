local MapState = {}
local dbg = require("debugger")
MapState.__index = MapState

local constants = require("src/Constants")

local MAP_X_MAX = 68
local MAP_Y_MAX = 28

local move_mod = 0.02

local BLINK_TICK_COUNT = 20

function MapState:init()
    local this = {
        dtotal = 0,             -- Delta time total
        zoom_level = 1,         -- Zoom level is how far into the map we are looking.
        current_x_offset = 0,
        current_y_offset = 0,
        blink_cursor_on = true,
        ticks_advanced = BLINK_TICK_COUNT,
    }
    setmetatable(this, self)

    return this
end

function MapState:_draw_breadcrumbs(renderer, player_info)
    -- Vector
    local accum = 0
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("V: ", 0, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string("\4 ", 0, accum)

    -- Distance
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("X: ", 0, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(player_info.overmap_x + self.current_x_offset), 0, accum)
    accum = accum + renderer:draw_string(" ", 0, accum)

    renderer:set_color("gray")
    accum = accum + renderer:draw_string("Y: ", 0, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(player_info.overmap_y + self.current_y_offset), 0, accum)
    accum = accum + renderer:draw_string(" ", 0, accum)

    -- Zoom level
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("Z: ", 0, accum)
    renderer:set_color("red")
    accum = accum + renderer:draw_string(tostring(math.floor(self.zoom_level)), 0, accum)
end

function MapState:_draw_map(renderer, player_info)
    local row_offset = 1
    local column_offset = 6
    local multiplier = 100

    local zoom = self.zoom_level * 0.02

    -- Player's location on the overmap
    local deproj_player_x = zoom * -(MAP_X_MAX/2) + player_info.overmap_x
    local deproj_player_y = zoom * -(MAP_Y_MAX/2) + player_info.overmap_y

    for x=0, MAP_X_MAX do
        for y=0, MAP_Y_MAX do
            -- This builds a weird scramble:
            -- local raw_noise_val = love.math.noise(
            --     x + (zoom * self.current_x_offset),
            --     y + (zoom * self.current_y_offset))
            -- local noise_val = raw_noise_val * 1000
            local noise_x = (zoom * (x - MAP_X_MAX/2)) + self.current_x_offset + player_info.overmap_x
            local noise_y = (zoom * (y - MAP_Y_MAX/2)) + self.current_y_offset + player_info.overmap_y

            local raw_noise_val = love.math.noise(noise_x, noise_y)
            local noise_val = raw_noise_val * 1000

            if self.blink_cursor_on and deproj_player_x == noise_x and deproj_player_y == noise_y then
                renderer:set_color("cyan")
            elseif noise_val < 250 then
                renderer:set_color("grayest")
            elseif noise_val < 500 then
                renderer:set_color("grayer")
            elseif noise_val < 750 then
                renderer:set_color("gray")
            else
                renderer:set_color("white")
            end
            --if math.floor(noise_val) % 10 == 0 then
                renderer:draw_raw_numbers({178}, y + 1, x + row_offset)
            --end
        end
    end
end

function MapState:key_pressed(game_state, key)
end

function MapState:update(game_state, dt)
    self.dtotal = self.dtotal + dt
    if self.dtotal >= constants.TICKER_RATE then
        self.dtotal = self.dtotal - constants.TICKER_RATE

        self.ticks_advanced = self.ticks_advanced - 1
        if self.ticks_advanced <= 0 then
            -- Reset the counter.
            self.ticks_advanced = BLINK_TICK_COUNT
            self.blink_cursor_on = not self.blink_cursor_on
        end

        if love.keyboard.isDown("left") then
            self.current_x_offset = self.current_x_offset - move_mod
        end
        if love.keyboard.isDown("right") then
            self.current_x_offset = self.current_x_offset + move_mod
        end
        if love.keyboard.isDown("up") then
            self.current_y_offset = self.current_y_offset - move_mod
        end
        if love.keyboard.isDown("down") then
            self.current_y_offset = self.current_y_offset + move_mod
        end

        local ZOOM_MOD = 0.02
        if love.keyboard.isDown("pageup") then
            self.zoom_level = self.zoom_level - ZOOM_MOD
        end
        if love.keyboard.isDown("pagedown") then
            self.zoom_level = self.zoom_level + ZOOM_MOD
        end

        if self.zoom_level < 1 then
            self.zoom_level = 1
        end
    end
end

function MapState:render(renderer, game_state)
    local player_info = game_state:get_player_info()

    self:_draw_breadcrumbs(renderer, player_info)
    self:_draw_map(renderer, player_info)
end

return MapState

