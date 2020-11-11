local MapState = {}
local dbg = require("debugger")
MapState.__index = MapState

local constants = require("src/Constants")

local move_mod = 0.02
local ZOOM_MOD = 0.02

local LATTICE_NOISE_OFFSET_X = 48765
local LATTICE_NOISE_OFFSET_Y = 32455

local WEATHER_NOISE_OFFSET_X = 48765
local WEATHER_NOISE_OFFSET_Y = 32455

local BLINK_TICK_COUNT = 20

local O_NONE = 1
local O_WEATHER = 2
local O_LATTICE = 3
local MAP_OVERLAYS = {
    O_NONE,
    O_WEATHER,
    O_LATTICE,
}

function MapState:init()
    local zoom = ZOOM_MOD -- Actually zoom * ZOOM_MOD, but 1 *... whatever you get it.
    local this = {
        dtotal = 0,             -- Delta time total
        zoom_level = 1,         -- Zoom level is how far into the map we are looking.
        current_x_offset = zoom * (-constants.MAP_X_MAX/2),
        current_y_offset = zoom * (-constants.MAP_Y_MAX/2),
        blink_cursor_on = true,
        ticks_advanced = BLINK_TICK_COUNT,

        current_map_overlay = MAP_OVERLAYS[1],

        current_lattice_step = 1

    }
    setmetatable(this, self)

    return this
end

function MapState:_draw_breadcrumbs(renderer, player_info)
    -- Vector
    local accum = 0
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("O: ", 0, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(self.current_map_overlay) .. " ", 0, accum)
    -- renderer:set_color("white")
    -- accum = accum + renderer:draw_string("\4 ", 0, accum)

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

    local zoom = self.zoom_level * ZOOM_MOD

    -- Player's location on the overmap
    local deproj_player_x = zoom * -(constants.MAP_X_MAX/2) + player_info.overmap_x
    local deproj_player_y = zoom * -(constants.MAP_Y_MAX/2) + player_info.overmap_y

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            -- This builds a weird scramble:
            -- local raw_noise_val = love.math.noise(
            --     x + (zoom * self.current_x_offset),
            --     y + (zoom * self.current_y_offset))
            -- local noise_val = raw_noise_val * 1000
            local noise_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset + player_info.overmap_x
            local noise_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset + player_info.overmap_y

            local raw_noise_val = love.math.noise(noise_x, noise_y)
            local noise_val = raw_noise_val * 1000

            if self.blink_cursor_on and deproj_player_x == noise_x and deproj_player_y == noise_y then
                renderer:set_color("cyan")
            elseif noise_val < 550 then
                renderer:set_color("white")
            elseif noise_val < 750 then
                renderer:set_color("gray")
            elseif noise_val < 900 then
                renderer:set_color("grayer")
            else
                renderer:set_color("grayest")
            end
            --if math.floor(noise_val) % 10 == 0 then
                renderer:draw_raw_numbers({178}, y + 1, x + row_offset)
            --end
        end
    end
end

function MapState:key_pressed(game_state, key)
    if key == "h" then
        -- Snap to home
        self.zoom_level = 1
        local zoom = self.zoom_level * ZOOM_MOD
        self.current_x_offset = zoom * (-constants.MAP_X_MAX/2)
        self.current_y_offset = zoom * (-constants.MAP_Y_MAX/2)
    elseif key == "tab" then
        self.current_map_overlay = math.fmod(self.current_map_overlay, #MAP_OVERLAYS) + 1
    elseif key == "space" then
        game_state:set_paused(not game_state:get_paused())
    elseif key == "escape" then
        game_state:set_menu_open(not game_state:get_menu_open())
    end
end

function MapState:_handle_keys(game_state, dt)
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

        if not game_state:get_paused() then
            self.current_lattice_step = self.current_lattice_step + 0.0002
        end

        self:_handle_keys(game_state, dt)
    end
end

function MapState:_draw_weather(renderer, player_info)
    local row_offset = 1
    local column_offset = 6

    local zoom = self.zoom_level * ZOOM_MOD

    local WEATHER_MAP_DIVISOR = 1600
    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            local noise_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset + player_info.overmap_x
            local noise_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset + player_info.overmap_y
            local raw_noise_val = love.math.noise(noise_x, noise_y, self.current_lattice_step)
            local noise_val = math.floor(raw_noise_val * WEATHER_MAP_DIVISOR)

            renderer:set_color("grayest")
            renderer:draw_raw_numbers({char}, y + 1, x + row_offset)

            if noise_val < WEATHER_MAP_DIVISOR/2 then
                if math.fmod(x, 2) == 0 and math.fmod(y, 2) == 0 then
                    for i=0,8 do
                        if noise_val * 2 < (i * WEATHER_MAP_DIVISOR/8) then
                            renderer:draw_raw_numbers({i - 1}, y + 1, x + row_offset)
                            break
                        end
                    end
                end
            else
                for i=0,8 do
                    if noise_val * 2 < (i * WEATHER_MAP_DIVISOR/8) then
                        renderer:draw_raw_numbers({i - 1}, y + 1, x + row_offset)
                        break
                    end
                end
            end
        end
    end
end

function MapState:_draw_lattice(renderer, player_info)
    local row_offset = 1
    local column_offset = 6

    local zoom = self.zoom_level * ZOOM_MOD

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            -- This builds a weird scramble:
            local noise_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset + player_info.overmap_x + LATTICE_NOISE_OFFSET_X
            local noise_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset + player_info.overmap_y + LATTICE_NOISE_OFFSET_Y
            local raw_noise_val = love.math.noise(noise_x, noise_y, self.current_lattice_step)
            local noise_val = math.floor(raw_noise_val * 1000)

            if noise_val < 250 then
                renderer:set_color("blood")
                local char = 194 + math.fmod(noise_val, 4)
                renderer:draw_raw_numbers({char}, y + 1, x + row_offset)
            elseif noise_val < 300 then
                renderer:set_color("red")
                local char = 196 + math.fmod(noise_val, 10)
                renderer:draw_raw_numbers({char}, y + 1, x + row_offset)
            end
        end
    end
end

function MapState:_draw_menu(renderer, player_info)
    local x = 1
    local y = 1
    local w = constants.MAP_X_MAX/4
    local h = constants.MAP_Y_MAX - y
    renderer:render_window(x, y, w, h, "black", "white")
end

function MapState:render(renderer, game_state)
    local player_info = game_state:get_player_info()

    self:_draw_breadcrumbs(renderer, player_info)
    self:_draw_map(renderer, player_info)
    if game_state:get_menu_open() then
        self:_draw_menu(renderer, player_info)
    end

    if self.current_map_overlay == O_WEATHER then
        self:_draw_weather(renderer, player_info)
    elseif self.current_map_overlay == O_LATTICE then
        self:_draw_lattice(renderer, player_info)
    end
end

return MapState

