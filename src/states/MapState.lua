local Screen = require("src/Screen")
local MapState = Screen.extend()

local constants = require("src/Constants")
local Utils = require("src/Utils")

local commands = require("src/sim/commands")
local context_actions = require("src/ui/context_actions")
local Fields = require("src/sim/fields")
local Input = require("src/Input")
local ModalMenu = require("src/ui/ModalMenu")

-- World units per map cell at zoom level 1.
local ZOOM_MOD = 0.02

-- Keys that do something for as long as they are held.
local HELD_KEYS = {"left", "right", "up", "down", "pageup", "pagedown"}

local TERRAIN_GLYPH = 178

local O_NONE = 1
local O_WEATHER = 2
local O_LATTICE = 3
local MAP_OVERLAYS = {
    O_NONE,
    O_WEATHER,
    O_LATTICE,
}

function MapState:init(game_state)
    local home = game_state:get_hull_position()
    local this = {
        zoom_level = 1,
        current_x_offset = home.x,
        current_y_offset = home.y,

        current_map_overlay = MAP_OVERLAYS[1],

        cursor_mode = nil,
        cursor_x = 0,
        cursor_y = 0,

        menu = nil,             -- The open context menu, if any.

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
    local home = game_state:get_hull_position()
    local tick = math.floor(game_state:get_cur_tick())
    local in_weather = game_state.fields:in_weather(home.x, home.y, game_state.clock.sim.time)
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

function MapState:_get_zoom()
    return self.zoom_level * ZOOM_MOD
end

-- World coordinates <-> map cells.
function MapState:_cell_to_world(cell_x, cell_y)
    local zoom = self:_get_zoom()
    return (zoom * (cell_x - constants.MAP_X_MAX/2)) + self.current_x_offset,
           (zoom * (cell_y - constants.MAP_Y_MAX/2)) + self.current_y_offset
end

function MapState:_world_to_cell(world_x, world_y)
    local zoom = self:_get_zoom()
    return math.floor(((world_x - self.current_x_offset) / zoom) + (constants.MAP_X_MAX/2)),
           math.floor(((world_y - self.current_y_offset) / zoom) + (constants.MAP_Y_MAX/2))
end

local function _cell_is_on_map(x, y)
    return x < constants.MAP_X_MAX and x >= 1 and y < constants.MAP_Y_MAX and y >= 1
end

function MapState:_draw_breadcrumbs(renderer, game_state)
    -- Vector
    local accum = 1
    renderer:set_color("gray")
    accum = accum + renderer:draw_string("O: ", 0, accum)
    renderer:set_color("white")
    accum = accum + renderer:draw_string(tostring(self.current_map_overlay) .. " ", 0, accum)

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
    accum = accum + renderer:draw_traumae_string(tostring(math.floor(game_state:get_cur_tick())), 0, accum/2)
end

-- The terrain only changes when the view moves or something that lifts the
-- fog does, so its glyphs are kept in a layer and reused between redraws.
function MapState:_draw_map(renderer, game_state)
    local world = game_state.world

    -- Half a map cell is as precisely as the fog's edge can be seen, so a
    -- crawling frame only forces a rebuild every second or so.
    local key_parts = {self.current_x_offset, self.current_y_offset, self.zoom_level}
    local half_cell = self:_get_zoom() / 2
    local revealers = world:query("Position", "FogReveal")
    for i=1, #revealers do
        local position = world:get(revealers[i], "Position")
        table.insert(key_parts, math.floor(position.x / half_cell))
        table.insert(key_parts, math.floor(position.y / half_cell))
    end
    local key = table.concat(key_parts, ",")

    if not self.terrain_layer then
        self.terrain_layer = renderer:new_layer()
    end
    if key ~= self.terrain_key then
        self.terrain_key = key
        renderer:begin_layer(self.terrain_layer)
        self:_build_terrain(renderer, game_state, revealers)
        renderer:end_layer()
    end
    renderer:draw_layer(self.terrain_layer)
end

local function _terrain_color(noise_val)
    if noise_val <= 16 then
        return nil -- Black on black.
    elseif noise_val <= 20 then
        return "blood"
    elseif noise_val <= 25 then
        return "red"
    elseif noise_val < 550 then
        return "white"
    elseif noise_val < 750 then
        return "gray"
    elseif noise_val < 900 then
        return "grayer"
    end
    return "grayest"
end

function MapState:_build_terrain(renderer, game_state, revealers)
    local world = game_state.world
    local fields = game_state.fields

    -- Squared radii, so the inner loop needs no square roots.
    local lit = {}
    for i=1, #revealers do
        local position = world:get(revealers[i], "Position")
        local radius = world:get(revealers[i], "FogReveal").radius
        table.insert(lit, {x = position.x, y = position.y, radius_squared = radius * radius})
    end

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            local world_x, world_y = self:_cell_to_world(x, y)

            local visible = false
            for i=1, #lit do
                local dx, dy = lit[i].x - world_x, lit[i].y - world_y
                if dx * dx + dy * dy < lit[i].radius_squared then
                    visible = true
                    break
                end
            end

            local color = visible and _terrain_color(fields:terrain(world_x, world_y))
            if color then
                renderer:set_color(color)
                renderer:draw_glyph(TERRAIN_GLYPH, y + 1, x + 1)
            end
        end
    end
end

-- Overlays are only known about within the hull's own sensor range.
function MapState:_each_overlay_cell(game_state, fn)
    local home = game_state:get_hull_position()
    local radius = game_state.world:get(game_state.world.res.hull, "FogReveal").radius

    for x=0, constants.MAP_X_MAX do
        for y=0, constants.MAP_Y_MAX do
            local world_x, world_y = self:_cell_to_world(x, y)
            if Utils.dist(home.x, home.y, world_x, world_y) <= radius then
                fn(x, y, world_x, world_y)
            end
        end
    end
end

function MapState:_draw_weather(renderer, game_state)
    local sim_time = game_state.clock.sim.time
    local divisor = Fields.WEATHER_MAP_DIVISOR

    renderer:set_color("grayest")
    self:_each_overlay_cell(game_state, function(x, y, world_x, world_y)
        local noise_val = game_state.fields:weather(world_x, world_y, sim_time)

        -- Heavy weather is drawn sparsely, light weather on every cell.
        local sparse = noise_val < divisor/2
        if not sparse or (math.fmod(x, 2) == 0 and math.fmod(y, 2) == 0) then
            for i=1, 8 do
                if noise_val * 2 < (i * divisor/8) then
                    renderer:draw_glyph(i - 1, y + 1, x + 1)
                    break
                end
            end
        end
    end)
end

function MapState:_draw_lattice(renderer, game_state)
    local sim_time = game_state.clock.sim.time

    self:_each_overlay_cell(game_state, function(x, y, world_x, world_y)
        local noise_val = game_state.fields:lattice_intensity(world_x, world_y, sim_time)
        if noise_val < constants.LATTICE_MINUMUM_INTENSITY - 50 then
            renderer:set_color("blood")
            renderer:draw_glyph(194 + math.fmod(noise_val, 4), y + 1, x + 1)
        elseif noise_val < constants.LATTICE_MINUMUM_INTENSITY then
            renderer:set_color("red")
            renderer:draw_glyph(196 + math.fmod(noise_val, 10), y + 1, x + 1)
        end
    end)
end

-- The entity on the map nearest the cursor, or nil.
function MapState:_get_closest_object(game_state)
    local world = game_state.world
    local cursor_x = math.floor(self.cursor_x)
    local cursor_y = math.floor(self.cursor_y)

    local closest, shortest_distance = nil, nil
    local objects = world:query("Position", "Icon")
    for i=1, #objects do
        local position = world:get(objects[i], "Position")
        local x, y = self:_world_to_cell(position.x, position.y)
        local distance = Utils.dist(cursor_x, cursor_y, x, y)
        if not shortest_distance or distance < shortest_distance then
            shortest_distance = distance
            closest = objects[i]
        end
    end

    return closest
end

function MapState:_open_context_menu(game_state)
    local world = game_state.world
    local target_x, target_y = self:_cell_to_world(self.cursor_x, self.cursor_y)

    local function close()
        self.menu = nil
    end

    local items = {}
    local closest = self:_get_closest_object(game_state)
    if closest then
        -- A heading, then whatever can be done with the thing under the cursor.
        table.insert(items, {name = world:get(closest, "Named").name, enabled = false})
        local actions = context_actions.for_entity(world, closest, target_x, target_y, close)
        for i=1, #actions do
            table.insert(items, actions[i])
        end
    end

    table.insert(items, {name = "Dispatch", enabled = commands.can_dispatch(world), callback = function()
        commands.dispatch(world, target_x, target_y)
        close()
    end})
    table.insert(items, {name = "Cancel", enabled = true, callback = close})

    self.menu = ModalMenu:init(self.cursor_x, self.cursor_y, items, "white", "black")
end

function MapState:key_pressed(game_state, key)
    self:_watch_held_keys(game_state)

    if self.menu then
        return self.menu:key_pressed(game_state, key)
    end

    if key == "h" then
        -- Snap to home
        local home = game_state:get_hull_position()
        self.zoom_level = 1
        self.current_x_offset = home.x
        self.current_y_offset = home.y
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
            self:_open_context_menu(game_state)
            self.cursor_mode = nil
        end
    end
end

function MapState:_handle_keys(game_state, dt)
    if self.menu then
        return
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

    self.cursor_x = math.max(0, math.min(self.cursor_x, constants.MAP_X_MAX))
    self.cursor_y = math.max(0, math.min(self.cursor_y, constants.MAP_Y_MAX))

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

function MapState:render(renderer, game_state)
    local world = game_state.world
    local blink_on = game_state.clock:blink_on()

    self:_draw_breadcrumbs(renderer, game_state)
    self:_draw_map(renderer, game_state)
    if self.current_map_overlay == O_WEATHER then
        self:_draw_weather(renderer, game_state)
    elseif self.current_map_overlay == O_LATTICE then
        self:_draw_lattice(renderer, game_state)
    end

    -- Things in the world. In cursor mode the one that would be selected blinks green.
    local closest = self.cursor_mode and self:_get_closest_object(game_state)
    local objects = world:query("Position", "Icon")
    for i=1, #objects do
        local entity = objects[i]
        local position = world:get(entity, "Position")
        local x, y = self:_world_to_cell(position.x, position.y)

        if _cell_is_on_map(x, y) then
            if entity ~= closest then
                renderer:set_color("red")
                renderer:draw_glyph(world:get(entity, "Icon").glyph, y + 1, x + 1)
            elseif blink_on then
                renderer:set_color("green")
                renderer:draw_glyph(world:get(entity, "Icon").glyph, y + 1, x + 1)
            end
        end
    end

    -- Us.
    if blink_on then
        local home = game_state:get_hull_position()
        local x, y = self:_world_to_cell(home.x, home.y)
        if _cell_is_on_map(x, y) then
            renderer:set_color("cyan")
            renderer:draw_glyph(TERRAIN_GLYPH, y + 1, x + 1)
        end
    end

    if self.cursor_mode then
        renderer:set_color("red")
        renderer:draw_glyph(TERRAIN_GLYPH, math.floor(self.cursor_y) + 1, math.floor(self.cursor_x) + 1)
    end

    if self.menu then
        self.menu:render(renderer)
    end

    if self.in_weather then
        local warning_text = "* WEATHER WARNING *"
        local x = constants.MAP_X_MAX/2 - ((string.len(warning_text) + 4) / 2)
        local y = constants.MAP_Y_MAX - 5

        renderer:render_window_with_text(x, y, warning_text, "red", "white")
    end
end

return MapState
