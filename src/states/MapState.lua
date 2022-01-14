local MapState = {}
MapState.__index = MapState

local constants = require("src/Constants")
local Utils = require("src/Utils")

local ModalMenu = require("src/ui/ModalMenu")

local move_mod = 0.02
local cursor_move_mod = 0.4
local ZOOM_MOD = 0.02

local FOG_OF_WAR_RADIUS = 0.75

local WEATHER_NOISE_OFFSET_X = 55333
local WEATHER_NOISE_OFFSET_Y = 46464

local BLINK_TICK_COUNT = 20

local O_NONE = 1
local O_WEATHER = 2
local O_LATTICE = 3
local MAP_OVERLAYS = {
    O_NONE,
    O_WEATHER,
    O_LATTICE,
}

function MapState:init(game_state)
    local this = {
        dtotal = 0,             -- Delta time total
        zoom_level = 1,         -- Zoom level is how far into the map we are looking.
        current_x_offset = game_state.player_info.overmap_x,
        current_y_offset = game_state.player_info.overmap_y,
        blink_cursor_on = true,
        ticks_advanced = BLINK_TICK_COUNT,

        current_map_overlay = MAP_OVERLAYS[1],
        current_time = GENESIS,

        current_weather_step = 1,

        cursor_mode = nil,
        cursor_x = 0,
        cursor_y = 0,

        menus = {},
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
    accum = accum + renderer:draw_string(string.format("%.2f",self.current_x_offset), 0, accum)
    accum = accum + renderer:draw_string(" ", 0, accum)

    renderer:set_color("gray")
    accum = accum + renderer:draw_string("Y: ", 0, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(string.format("%.2f",self.current_y_offset), 0, accum)
    accum = accum + renderer:draw_string(" ", 0, accum)

    -- Zoom level
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("Z: ", 0, accum)
    renderer:set_color("red")
    accum = accum + renderer:draw_string(tostring(math.floor(self.zoom_level)), 0, accum)
    accum = accum + renderer:draw_string(" ", 0, accum)

    -- Tick time
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("T: ", 0, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_traumae_string(tostring(math.floor(player_info.cur_tick)), 0, accum/2)
end

function MapState:_draw_map(renderer, player_info)
    local row_offset = 1
    local column_offset = 6

    local zoom = self.zoom_level * ZOOM_MOD

    local player_x = math.floor(((player_info.overmap_x - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2))
    local player_y = math.floor(((player_info.overmap_y - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            local noise_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset
            local noise_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset

            local raw_noise_val = love.math.noise(noise_x, noise_y)
            local noise_val = raw_noise_val * 1000

            local distance_from_home = Utils.dist(player_info.overmap_x, player_info.overmap_y, noise_x, noise_y)
            --print("distance_from_home: " .. tostring(player_info.overmap_x) .. " " .. tostring(player_info.overmap_y) 
            --    .. ", " .. noise_x .. " " .. noise_y)

            if distance_from_home < FOG_OF_WAR_RADIUS then
                if noise_val <= 25 then
                    if noise_val <= 16 then
                        renderer:set_color("black")
                    elseif noise_val <= 20 then
                        renderer:set_color("blood")
                    elseif noise_val <= 25 then
                        renderer:set_color("red")
                    end
                elseif noise_val < 550 then
                    renderer:set_color("white")
                elseif noise_val < 750 then
                    renderer:set_color("gray")
                elseif noise_val < 900 then
                    renderer:set_color("grayer")
                else
                    renderer:set_color("grayest")
                end
            else
                renderer:set_color("black")
            end

            renderer:draw_raw_numbers({178}, y + 1, x + row_offset)
        end
    end
end

function MapState:insert_frame_nav_menu(game_state)
    exit_callback = function () table.remove(self.menus, 1) end
    dispatch_item = {["name"]="Dispatch", ["enabled"] = game_state.player_info:has_dispatchable(), ["callback"]=exit_callback}
    cancel_item = {["name"]="Cancel", ["enabled"] = true, ["callback"]=exit_callback}

    items = {dispatch_item, cancel_item}
    new_menu = ModalMenu:init(game_state, self.cursor_x, self.cursor_y, items, exit_callback)
    table.insert(self.menus, new_menu)
end

function MapState:key_pressed(game_state, key)
    if #self.menus >= 1 then
        return self.menus[1]:key_pressed(game_state, key)
    end

    if key == "h" then
        -- Snap to home
        self.zoom_level = 1
        local zoom = self.zoom_level * ZOOM_MOD
        self.current_x_offset = game_state.player_info.overmap_x
        self.current_y_offset = game_state.player_info.overmap_y
    elseif key == "tab" then
        self.current_map_overlay = math.fmod(self.current_map_overlay, #MAP_OVERLAYS) + 1
    elseif key == "space" then
        game_state:set_paused(not game_state:get_paused())
    elseif key == "return" then
        if self.cursor_mode == nil then
            self.cursor_mode = "cursor"
            self.cursor_x = constants.MAP_X_MAX/2
            self.cursor_y = constants.MAP_Y_MAX/2 - 1
            print("Cursor mode: " .. tostring(cursor_mode) .. " " .. self.cursor_x .. " " .. self.cursor_y)
        elseif self.cursor_mode == "cursor" then
            self:insert_frame_nav_menu(game_state)
            self.cursor_mode = nil
        end
    elseif key == "escape" then
        game_state:set_menu_open(not game_state:get_menu_open())
    end
end

function MapState:_handle_keys(game_state, dt)
    if #self.menus >= 1 then
        return self.menus[1]:handle_keys(game_state, dt)
    end

    if love.keyboard.isDown("left") then
        if self.cursor_mode then
            self.cursor_x = self.cursor_x - cursor_move_mod
        else
            self.current_x_offset = self.current_x_offset - move_mod
        end
    end
    if love.keyboard.isDown("right") then
        if self.cursor_mode then
            self.cursor_x = self.cursor_x + cursor_move_mod
        else
            self.current_x_offset = self.current_x_offset + move_mod
        end
    end
    if love.keyboard.isDown("up") then
        if self.cursor_mode then
            self.cursor_y = self.cursor_y - cursor_move_mod
        else
            self.current_y_offset = self.current_y_offset - move_mod
        end
    end
    if love.keyboard.isDown("down") then
        if self.cursor_mode then
            self.cursor_y = self.cursor_y + cursor_move_mod
        else
            self.current_y_offset = self.current_y_offset + move_mod
        end
    end

    if self.cursor_x > constants.MAP_X_MAX then
        self.cursor_x = constants.MAP_X_MAX
    elseif self.cursor_x < 0 then
        self.cursor_x = 0
    end

    if self.cursor_y > constants.MAP_Y_MAX then
        self.cursor_y = constants.MAP_Y_MAX
    elseif self.cursor_y < 0 then
        self.cursor_y = 0
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

function MapState:update(game_state, dt, is_active)
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
            self.current_weather_step = self.current_weather_step + 0.0002
        end

        if is_active then
            self:_handle_keys(game_state, dt)
        end
    end
end

function MapState:_draw_weather(renderer, player_info)
    local row_offset = 1
    local column_offset = 6

    local zoom = self.zoom_level * ZOOM_MOD

    local WEATHER_MAP_DIVISOR = 1600
    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            local noise_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset
            local noise_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset
            local raw_noise_val = love.math.noise(noise_x, noise_y, self.current_weather_step)
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
            local world_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset
            local world_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset
            local noise_val = player_info:get_lattice_intensity(world_x, world_y)

            if noise_val < constants.LATTICE_MINUMUM_INTENSITY - 50 then
                renderer:set_color("blood")
                local char = 194 + math.fmod(noise_val, 4)
                renderer:draw_raw_numbers({char}, y + 1, x + row_offset)
            elseif noise_val < constants.LATTICE_MINUMUM_INTENSITY then
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
    if self.current_map_overlay == O_WEATHER then
        self:_draw_weather(renderer, player_info)
    elseif self.current_map_overlay == O_LATTICE then
        self:_draw_lattice(renderer, player_info)
    end

    local row_offset = 1
    local frames = game_state.player_info:get_frames()
    local zoom = self.zoom_level * ZOOM_MOD
    for i=1, #frames do
        local frame = frames[i]
        if frame:get_deployed() then
            local deproj_frame_x = zoom * -(constants.MAP_X_MAX/2) + frame:get_x()
            local deproj_frame_y = zoom * -(constants.MAP_Y_MAX/2) + frame:get_y()
            local x = math.floor(((frame:get_x() - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2))
            local y = math.floor(((frame:get_y() - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))

            if x < constants.MAP_X_MAX and x >= 1 and y < constants.MAP_Y_MAX and y >= 1 then
                renderer:set_color("red")
                renderer:draw_raw_numbers({178}, y + 1, x + row_offset)
            end
        end
    end

    if self.blink_cursor_on then
        renderer:set_color("cyan")
        local x = math.floor(((player_info.overmap_x - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2))
        local y = math.floor(((player_info.overmap_y - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))
        if x < constants.MAP_X_MAX and x >= 1 and y < constants.MAP_Y_MAX and y >= 1 then
            renderer:draw_raw_numbers({178}, y + 1, x + row_offset)
        end
    end

    if self.cursor_mode then
        local x = math.floor(self.cursor_x)
        local y = math.floor(self.cursor_y)

        renderer:set_color("red")
        renderer:draw_raw_numbers({178}, y + 1, x + row_offset)
    end

    for i=1, #self.menus do
        local menu = self.menus[i]
        menu:render(renderer, player_info)
    end

    if game_state:get_menu_open() then
        self:_draw_menu(renderer, player_info)
    end
end

return MapState

