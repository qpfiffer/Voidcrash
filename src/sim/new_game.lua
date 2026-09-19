-- Builds the world a new game starts with.
local constants = require("src/Constants")
local Utils = require("src/Utils")
local World = require("src/ecs/World")

local movement = require("src/ecs/systems/movement")
local orders = require("src/ecs/systems/orders")
local prefabs = require("src/ecs/prefabs")
local radio_log = require("src/ecs/systems/radio_log")

-- opts (all optional, for tests): x, y, frame_names
return function(opts)
    opts = opts or {}
    local world = World.new()

    -- Order matters: an order that starts a move should move in the same step.
    world:add_system(orders.system)
    world:add_system(movement.system)

    local hull = prefabs.hull(world,
        opts.x or math.random(constants.OVERMAP_MAX_X),
        opts.y or math.random(constants.OVERMAP_MAX_Y))
    world.res.hull = hull

    local frame_names = opts.frame_names
        or {Utils.generate_frame_name(), Utils.generate_frame_name(), Utils.generate_frame_name()}
    for i=1, #frame_names do
        prefabs.frame(world, frame_names[i], hull)
    end

    prefabs.em_field(world, hull)
    prefabs.lattice_array(world, hull)
    prefabs.sleeper(world, hull)
    world.res.radio = prefabs.radio(world, hull)

    -- What the T readout said when the game began.
    world.res.genesis_tick = math.random(constants.GENESIS)

    radio_log.install(world)

    return world
end
