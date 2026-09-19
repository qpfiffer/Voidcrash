local Screen = require("src/Screen")
local MapState = Screen.extend()

local constants = require("src/Constants")
local Utils = require("src/Utils")

local Input = require("src/Input")
local ModalMenu = require("src/ui/ModalMenu")
local ObjectType = require("src/objects/ObjectType")
local OrderType = require("src/management/OrderType")
local UnitCommand = require("src/management/UnitCommand")

-- World units per map cell at zoom level 1.
local ZOOM_MOD = 0.02

local FOG_OF_WAR_RADIUS = 0.75

local WEATHER_NOISE_OFFSET_X = 55333
local WEATHER_NOISE_OFFSET_Y = 46464
local WEATHER_MAP_DIVISOR = 1600

-- Keys that do something for as long as they are held.
local HELD_KEYS = {"left", "right", "up", "down", "pageup", "pagedown"}

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
        zoom_level = 1,
        current_x_offset = game_state.player_info.overmap_x,
        current_y_offset = game_state.player_info.overmap_y,
        blink_cursor_on = true, -- Refreshed from the shared clock blink on every render.

        current_map_overlay = MAP_OVERLAYS[1],

        cursor_mode = nil,
        cursor_x = 0,
        cursor_y = 0,

        world_tile_modifiers = {},

        menus = {},

        held_key_timer = nil,   -- Only exists while one of HELD_KEYS is down.
        overlay_timer = nil,    -- Only exists while an animated overlay is showing.
        terrain_layer = nil,    -- The terrain glyphs, rebuilt only when terrain_key changes.
        terrain_key = nil,
        in_weather = false,     -- Latched by _slow_refresh so render doesn't have to ask.
        shown_tick = nil,
    }
    setmetatable(this, self)

    return this
end

function MapState:get_name()
    return "MAP"
end

function MapState:uses_blink()
    return true
end

function MapState:on_start(game_state)
    -- Things on the map that change by themselves, slowly: the T readout and
    -- whether the weather has drifted over us.
    self.sim_timers:every(1, function() self:_slow_refresh(game_state) end)
end

function MapState:on_enter(game_state)
    self:_slow_refresh(game_state)
    self:_watch_held_keys(game_state)
end

function MapState:_slow_refresh(game_state)
    local player_info = game_state:get_player_info()
    local tick = math.floor(player_info:get_cur_tick())
    local in_weather = self:_player_is_in_weather(game_state, player_info)
    if tick ~= self.shown_tick or in_weather ~= self.in_weather then
        self.shown_tick = tick
        self.in_weather = in_weather
        game_state:invalidate()
    end
end

-- Held keys (pan, zoom, cursor) are applied by a ui timer, so they keep working
-- while paused. It only exists while a key is actually down: no keys, no wakeups.
function MapState:_watch_held_keys(game_state)
    if self.held_key_timer or not Input.any_down(HELD_KEYS) then
        return
    end

    self.held_key_timer = self.timers:every(1 / constants.HELD_KEY_HZ, function(elapsed)
        if not Input.any_down(HELD_KEYS) then
            self.held_key_timer:cancel()
            self.held_key_timer = nil
            return
        end
        self:_handle_keys(game_state, math.min(elapsed, 0.05))
    end)
end

-- The weather and lattice overlays are animated (on sim time), so while one is
-- showing the map needs regular redraws. Otherwise it needs none.
function MapState:_watch_overlay(game_state)
    local animated = self.current_map_overlay ~= O_NONE
    if animated and not self.overlay_timer then
        self.overlay_timer = self.sim_timers:every(1 / constants.OVERLAY_REDRAW_HZ, function()
            game_state:invalidate()
        end)
    elseif not animated and self.overlay_timer then
        self.overlay_timer:cancel()
        self.overlay_timer = nil
    end
end

-- Weather drifts with sim time: it freezes when paused and doesn't care who's on screen.
function MapState:_weather_step(game_state)
    return 1 + constants.WEATHER_RATE * game_state.clock.sim.time
end


function MapState:_draw_breadcrumbs(renderer, player_info)
    -- Vector
    local accum = 1
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
    accum = accum + renderer:draw_traumae_string(tostring(math.floor(player_info:get_cur_tick())), 0, accum/2)
end

-- The terrain only changes when the view moves or something that lifts the
-- fog does, so its glyphs are kept in a layer and reused between redraws.
function MapState:_draw_map(renderer, player_info)
    -- Objects lift the fog around them. Half a map cell is as precisely as that can
    -- be seen, so a crawling frame only forces a rebuild every second or so.
    local key_parts = {self.current_x_offset, self.current_y_offset, self.zoom_level}
    local half_cell = self:_get_zoom() / 2
    local world_objects = player_info:get_world_objects()
    for i=1, #world_objects do
        table.insert(key_parts, math.floor(world_objects[i]:get_x() / half_cell))
        table.insert(key_parts, math.floor(world_objects[i]:get_y() / half_cell))
    end
    local key = table.concat(key_parts, ",")

    if not self.terrain_layer then
        self.terrain_layer = renderer:new_layer()
    end
    if key ~= self.terrain_key then
        self.terrain_key = key
        renderer:begin_layer(self.terrain_layer)
        self:_build_terrain(renderer, player_info)
        renderer:end_layer()
    end
    renderer:draw_layer(self.terrain_layer)
end

function MapState:_build_terrain(renderer, player_info)
    local row_offset = 1
    local column_offset = 6

    local zoom = self:_get_zoom()

    -- World coords to screen coords
    local player_x = math.floor(((player_info.overmap_x - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2))
    local player_y = math.floor(((player_info.overmap_y - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            local noise_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset
            local noise_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset

            local raw_noise_val = love.math.noise(noise_x, noise_y)
            local noise_val = raw_noise_val * 1000

            local should_draw = false
            local distance_from_home = Utils.dist(player_info.overmap_x, player_info.overmap_y, noise_x, noise_y)
            --print("distance_from_home: " .. tostring(player_info.overmap_x) .. " " .. tostring(player_info.overmap_y) 
            --    .. ", " .. noise_x .. " " .. noise_y)
            should_draw = distance_from_home < FOG_OF_WAR_RADIUS

            if not should_draw then
                local world_objects = player_info:get_world_objects()
                for i in pairs(world_objects) do
                    local wobj = world_objects[i]
                    local distance = Utils.dist(wobj:get_x(), wobj:get_y(), noise_x, noise_y)
                    if distance < 0.25 then
                        should_draw = true
                        break
                    end
                end
            end

            if should_draw then
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

            renderer:draw_glyph(178, y + 1, x + row_offset)
        end
    end
end

function MapState:insert_frame_nav_menu(game_state)
    local zoom = self:_get_zoom()
    local cursor_world_x = (zoom * (self.cursor_x - constants.MAP_X_MAX/2)) + self.current_x_offset
    local cursor_world_y = (zoom * (self.cursor_y - constants.MAP_Y_MAX/2)) + self.current_y_offset

    local exit_callback = function () table.remove(self.menus, 1) end
    local dispatch_callback = function ()
        local dispatchable = game_state.player_info.hull:pop_item_from_cargo_of_type(ObjectType.DISPATCHABLE)
        dispatchable:set_deployed(true)
        dispatchable:add_order(game_state, UnitCommand:init(OrderType.MOVEMENT, {
            start_x = game_state.player_info.overmap_x,
            start_y = game_state.player_info.overmap_y,
            dest_x = cursor_world_x,
            dest_y = cursor_world_y
        }))

        game_state.player_info:add_world_object(dispatchable)
        exit_callback()
    end

    local closest_object_idx = self:_get_closest_object_index(game_state)
    local closest_object_context_item = nil
    local closest_object = nil
    if closest_object_idx then
        local world_objects = game_state.player_info:get_world_objects()
        closest_object = world_objects[closest_object_idx]
        closest_object_context_item = {["name"]=closest_object:get_name(), ["enabled"] = false, ["callback"]=exit_callback}
    end

    local dispatch_item = {["name"]="Dispatch", ["enabled"] = game_state.player_info.hull:has_dispatchable(), ["callback"]=dispatch_callback}
    local cancel_item = {["name"]="Cancel", ["enabled"] = true, ["callback"]=exit_callback}

    local items = nil
    if closest_object then
        items = {closest_object_context_item}
        local object_items = closest_object:get_context_cursor_items(game_state, exit_callback)
        for i=1, #object_items do
            table.insert(items, object_items[i])
        end
        table.insert(items, dispatch_item)
        table.insert(items, cancel_item)
    else
        items = {dispatch_item, cancel_item}
    end

    local bonus_data = {["x"] = cursor_world_x, ["y"] = cursor_world_y}
    local new_menu = ModalMenu:init(game_state, self.cursor_x, self.cursor_y, items, exit_callback, "white", "black", bonus_data)
    table.insert(self.menus, new_menu)
end

function MapState:key_pressed(game_state, key)
    self:_watch_held_keys(game_state)

    if #self.menus >= 1 then
        return self.menus[1]:key_pressed(game_state, key)
    end

    if key == "h" then
        -- Snap to home
        self.zoom_level = 1
        local zoom = self:_get_zoom()
        self.current_x_offset = game_state.player_info.overmap_x
        self.current_y_offset = game_state.player_info.overmap_y
    elseif key == "tab" then
        self.current_map_overlay = math.fmod(self.current_map_overlay, #MAP_OVERLAYS) + 1
        self:_watch_overlay(game_state)
    elseif key == "space" then
        game_state:set_paused(not game_state:get_paused())
    elseif key == "return" then
        if self.cursor_mode == nil then
            self.cursor_mode = "cursor"
            self.cursor_x = constants.MAP_X_MAX/2
            self.cursor_y = constants.MAP_Y_MAX/2 - 1
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

    local move_mod = constants.PAN_SPEED * dt
    local cursor_move_mod = constants.CURSOR_SPEED * dt

    if Input.is_down("left") then
        if self.cursor_mode then
            self.cursor_x = self.cursor_x - cursor_move_mod
        else
            self.current_x_offset = self.current_x_offset - move_mod
        end
    end
    if Input.is_down("right") then
        if self.cursor_mode then
            self.cursor_x = self.cursor_x + cursor_move_mod
        else
            self.current_x_offset = self.current_x_offset + move_mod
        end
    end
    if Input.is_down("up") then
        if self.cursor_mode then
            self.cursor_y = self.cursor_y - cursor_move_mod
        else
            self.current_y_offset = self.current_y_offset - move_mod
        end
    end
    if Input.is_down("down") then
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

    if Input.is_down("pageup") then
        self.zoom_level = self.zoom_level - constants.ZOOM_SPEED * dt
    end
    if Input.is_down("pagedown") then
        self.zoom_level = self.zoom_level + constants.ZOOM_SPEED * dt
    end

    if self.zoom_level < 1 then
        self.zoom_level = 1
    end
end

function MapState:_player_is_in_weather(game_state, player_info)
    local raw_noise_val = love.math.noise(player_info.overmap_x, player_info.overmap_y, self:_weather_step(game_state))
    local noise_val = math.floor(raw_noise_val * WEATHER_MAP_DIVISOR)

    --print("IS IN WEATHER: " .. noise_val)

    if noise_val <= WEATHER_MAP_DIVISOR/2 then
        return true
    end
end

function MapState:_get_zoom()
    return self.zoom_level * ZOOM_MOD
end

function MapState:_draw_weather(renderer, game_state, player_info)
    local weather_step = self:_weather_step(game_state)
    local row_offset = 1
    local column_offset = 6

    local zoom = self:_get_zoom()

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            local noise_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset
            local noise_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset

            local should_continue = false
            local distance_from_home = Utils.dist(player_info.overmap_x, player_info.overmap_y, noise_x, noise_y)
            if distance_from_home > FOG_OF_WAR_RADIUS then
                should_continue = true
            end

            if not should_continue then
                local raw_noise_val = love.math.noise(noise_x, noise_y, weather_step)
                local noise_val = math.floor(raw_noise_val * WEATHER_MAP_DIVISOR)

                renderer:set_color("grayest")

                if noise_val < WEATHER_MAP_DIVISOR/2 then
                    if math.fmod(x, 2) == 0 and math.fmod(y, 2) == 0 then
                        for i=0,8 do
                            if noise_val * 2 < (i * WEATHER_MAP_DIVISOR/8) then
                                renderer:draw_glyph(i - 1, y + 1, x + row_offset)
                                break
                            end
                        end
                    end
                else
                    for i=0,8 do
                        if noise_val * 2 < (i * WEATHER_MAP_DIVISOR/8) then
                            renderer:draw_glyph(i - 1, y + 1, x + row_offset)
                            break
                        end
                    end
                end
            end
        end
    end
end

function MapState:_draw_lattice(renderer, player_info)
    local row_offset = 1
    local column_offset = 6

    local zoom = self:_get_zoom()

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            -- This builds a weird scramble:
            local world_x = (zoom * (x - constants.MAP_X_MAX/2)) + self.current_x_offset
            local world_y = (zoom * (y - constants.MAP_Y_MAX/2)) + self.current_y_offset

            local should_continue = false
            local distance_from_home = Utils.dist(player_info.overmap_x, player_info.overmap_y, world_x, world_y)
            if distance_from_home > FOG_OF_WAR_RADIUS then
                should_continue = true
            end

            if not should_continue then
                local noise_val = player_info:get_lattice_intensity(world_x, world_y)
                if noise_val < constants.LATTICE_MINUMUM_INTENSITY - 50 then
                    renderer:set_color("blood")
                    local char = 194 + math.fmod(noise_val, 4)
                    renderer:draw_glyph(char, y + 1, x + row_offset)
                elseif noise_val < constants.LATTICE_MINUMUM_INTENSITY then
                    renderer:set_color("red")
                    local char = 196 + math.fmod(noise_val, 10)
                    renderer:draw_glyph(char, y + 1, x + row_offset)
                end
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

function MapState:_get_closest_object_index(game_state)
    local world_objects = game_state.player_info:get_world_objects()
    local shortest_distance = nil
    local zoom = self:_get_zoom()
    local closest_object_idx = nil

    for i=1, #world_objects do
        local w_object = world_objects[i]
        if w_object:get_deployed() then
            local x = math.floor(((w_object:get_x() - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2))
            local y = math.floor(((w_object:get_y() - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))
            local cursor_x = math.floor(self.cursor_x)
            local cursor_y = math.floor(self.cursor_y)
            local distance_from_home = Utils.dist(cursor_x, cursor_y, x, y)
            if not shortest_distance or distance_from_home < shortest_distance then
                shortest_distance = distance_from_home
                closest_object_idx = i
            end
        end
    end

    return closest_object_idx
end

function MapState:render(renderer, game_state)
    local player_info = game_state:get_player_info()
    self.blink_cursor_on = game_state.clock:blink_on()

    self:_draw_breadcrumbs(renderer, player_info)
    self:_draw_map(renderer, player_info)
    if self.current_map_overlay == O_WEATHER then
        self:_draw_weather(renderer, game_state, player_info)
    elseif self.current_map_overlay == O_LATTICE then
        self:_draw_lattice(renderer, player_info)
    end

    local row_offset = 1
    local world_objects = game_state.player_info:get_world_objects()
    local zoom = self:_get_zoom()

    local closest_object_idx = nil
    if self.cursor_mode then
        closest_object_idx = self:_get_closest_object_index(game_state)
    end

    for i=1, #world_objects do
        local w_object = world_objects[i]
        if w_object:get_deployed() then
            local deproj_frame_x = zoom * -(constants.MAP_X_MAX/2) + w_object:get_x()
            local deproj_frame_y = zoom * -(constants.MAP_Y_MAX/2) + w_object:get_y()
            local x = math.floor(((w_object:get_x() - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2))
            local y = math.floor(((w_object:get_y() - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))

            if x < constants.MAP_X_MAX and x >= 1 and y < constants.MAP_Y_MAX and y >= 1 then
                if not closest_object_idx then
                    renderer:set_color("red")
                    renderer:draw_glyph(w_object:get_icon(), y + 1, x + row_offset)
                else
                    if not self.cursor_mode or i ~= closest_object_idx then
                        renderer:set_color("red")
                        renderer:draw_glyph(w_object:get_icon(), y + 1, x + row_offset)
                    elseif self.blink_cursor_on and i == closest_object_idx then
                        renderer:set_color("green")
                        renderer:draw_glyph(w_object:get_icon(), y + 1, x + row_offset)
                    end
                end
            end
        end
    end

    if self.blink_cursor_on then
        renderer:set_color("cyan")
        local x = math.floor(((player_info.overmap_x - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2))
        local y = math.floor(((player_info.overmap_y - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))
        if x < constants.MAP_X_MAX and x >= 1 and y < constants.MAP_Y_MAX and y >= 1 then
            renderer:draw_glyph(178, y + 1, x + row_offset)
        end
    end

    if self.cursor_mode then
        local x = math.floor(self.cursor_x)
        local y = math.floor(self.cursor_y)

        renderer:set_color("red")
        renderer:draw_glyph(178, y + 1, x + row_offset)
    end

    for i=1, #self.menus do
        local menu = self.menus[i]
        menu:render(renderer, player_info)
    end

    if game_state:get_menu_open() then
        self:_draw_menu(renderer, player_info)
    end

    if self.in_weather then
        local warning_text = "* WEATHER WARNING *"
        local x = constants.MAP_X_MAX/2 - ((string.len(warning_text) + 4) / 2)
        local y = constants.MAP_Y_MAX - 5

        renderer:render_window_with_text(x, y, warning_text, "red", "white")

    end
end

return MapState

