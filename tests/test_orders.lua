local Clock = require("src/Clock")
local commands = require("src/sim/commands")
local containment = require("src/ecs/containment")
local constants = require("src/Constants")
local new_game = require("src/sim/new_game")

local tests = {}

-- Runs the world off a real Clock, the same way the game does.
local function _new_sim(sim_hz)
    local world = new_game({x = 100, y = 100, frame_names = {"AA-111", "BB-222"}})
    local clock = Clock.new({step = 1 / sim_hz, max_steps = 1000, max_catchup = 10})
    clock:on_step(function(step) world:step(step) end)
    clock:set_sim_active(function() return world:has_active_systems() end)

    local sim = {world = world, clock = clock}

    function sim.run_until_idle(limit_seconds)
        local waited = 0
        while world:has_active_systems() do
            clock:advance(0.05)
            waited = waited + 0.05
            assert(waited < limit_seconds, "sim never went idle")
        end
        return waited
    end

    function sim.messages()
        return world:get(world.res.radio, "RadioLog").messages
    end

    return sim
end

local EXPECTED_TRANSCRIPT = {
    "AA-111 is following new order.",
    "AA-111 begins to move.",
    "AA-111 has arrived at destination.",
    "AA-111 is following new order.",
    "AA-111 will dispatch next available item.",
    "AA-111 has deployed RL-01, Relay",
    "AA-111 is following new order.",
    "AA-111 is following new order.",
    "AA-111 begins to move.",
    "AA-111 has arrived at destination.",
    "AA-111 will rejoin the hull.",
    "AA-111 has rejoined the hull.",
}

local function _play_through(T, sim_hz)
    local sim = _new_sim(sim_hz)
    local world = sim.world
    local hull = world.res.hull

    T.eq(commands.can_dispatch(world), true)
    local frame = commands.dispatch(world, 100.3, 100.4)
    T.eq(world:get(frame, "Named").name, "AA-111", "frames leave in the order they were built")
    T.eq(world:has(frame, "InCargo"), false)

    -- 0.5 world units at FRAME_SPEED, give or take a step.
    local travel_time = sim.run_until_idle(120)
    T.near(travel_time, 0.5 / constants.FRAME_SPEED, 0.2)
    T.eq(world:get(frame, "Position").x, 100.3)
    T.eq(world:get(frame, "Position").y, 100.4)

    commands.drop(world, frame)
    sim.run_until_idle(5)
    local relays = world:query("Deployable", "Position")
    T.eq(#relays, 1)
    T.eq(world:get(relays[1], "Position").x, 100.3)
    T.list_eq(containment.contents(world, frame), {})

    commands.return_to_hull(world, frame)
    sim.run_until_idle(120)
    T.eq(world:get(frame, "InCargo").of, hull)
    T.eq(world:has(frame, "Position"), false)
    T.eq(world:has(frame, "Orders"), false)
    T.eq(world:has(frame, "Movement"), false)

    T.list_eq(sim.messages(), EXPECTED_TRANSCRIPT)
    return sim
end

function tests.dispatch_move_drop_return_at_60hz(T)
    _play_through(T, 60)
end

function tests.same_story_at_20hz(T)
    -- If anything were still tuned per tick instead of per second, this would differ.
    _play_through(T, 20)
end

function tests.pause_stops_frames(T)
    local sim = _new_sim(60)
    local frame = commands.dispatch(sim.world, 101, 100)
    for i=1, 20 do sim.clock:advance(0.05) end
    local x = sim.world:get(frame, "Position").x
    T.ok(x > 100 and x < 101)

    sim.clock:set_paused(true)
    for i=1, 20 do sim.clock:advance(0.05) end
    T.eq(sim.world:get(frame, "Position").x, x)
end

function tests.moving_to_where_you_already_are_finishes(T)
    local sim = _new_sim(60)
    local frame = commands.dispatch(sim.world, 100, 100) -- The hull's own position.
    sim.run_until_idle(2)
    T.eq(sim.world:has(frame, "Orders"), false)
end

function tests.dropping_with_nothing_to_drop_is_not_a_crash(T)
    local sim = _new_sim(60)
    local frame = commands.dispatch(sim.world, 100.01, 100)
    commands.drop(sim.world, frame)
    commands.drop(sim.world, frame)
    sim.run_until_idle(10)
    local messages = sim.messages()
    T.eq(messages[#messages], "AA-111 has nothing to deploy.")
end

function tests.embarking_needs_to_be_at_the_hull(T)
    local sim = _new_sim(60)
    local world = sim.world
    local frame = commands.dispatch(world, 100.5, 100)
    sim.run_until_idle(120)

    -- An embark order with no move home first.
    local orders = require("src/ecs/systems/orders")
    local C = require("src/ecs/components")
    local component = world:add(frame, "Orders", C.Orders())
    table.insert(component.queue, {kind = orders.EMBARK})
    sim.run_until_idle(5)

    T.eq(world:has(frame, "Position"), true)
    local messages = sim.messages()
    T.eq(messages[#messages], "AA-111 is too far from the hull to rejoin.")
end

function tests.things_in_the_hold_take_no_orders(T)
    local sim = _new_sim(60)
    local world = sim.world
    local stowed = containment.first_with(world, world.res.hull, "Dispatchable")
    T.eq(commands.move(world, stowed, 1, 1), false)
    T.eq(world:has(stowed, "Orders"), false)
    T.eq(world:has_active_systems(), false)
end

function tests.dispatching_with_an_empty_hold(T)
    local sim = _new_sim(60)
    T.ok(commands.dispatch(sim.world, 101, 101))
    T.ok(commands.dispatch(sim.world, 101, 101))
    T.eq(commands.can_dispatch(sim.world), false)
    T.eq(commands.dispatch(sim.world, 101, 101), nil)
end

function tests.radio_log_is_bounded(T)
    local sim = _new_sim(60)
    local radio_log = require("src/ecs/systems/radio_log")
    for i=1, 500 do
        radio_log.write(sim.world, "message " .. i)
    end
    local messages = sim.messages()
    T.eq(#messages, 200)
    T.eq(messages[#messages], "message 500")
end

return tests
