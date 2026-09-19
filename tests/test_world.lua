local World = require("src/ecs/World")
local C = require("src/ecs/components")
local containment = require("src/ecs/containment")
local hull_queries = require("src/sim/hull_queries")
local new_game = require("src/sim/new_game")

local tests = {}

function tests.ids_are_never_reused(T)
    local world = World.new()
    local a = world:spawn({Named = C.Named("a")})
    world:destroy(a)
    world:flush()
    local b = world:spawn({Named = C.Named("b")})
    T.ok(b > a)
    T.eq(world:alive(a), false)
    T.eq(world:get(a, "Named"), nil)
end

function tests.queries_match_all_components_in_id_order(T)
    local world = World.new()
    local a = world:spawn({Position = C.Position(0, 0), Icon = C.Icon(1)})
    local b = world:spawn({Position = C.Position(0, 0)})
    local c = world:spawn({Position = C.Position(0, 0), Icon = C.Icon(2)})
    T.list_eq(world:query("Position", "Icon"), {a, c})
    T.list_eq(world:query("Position"), {a, b, c})
    T.list_eq(world:query("Nothing"), {})
end

function tests.query_cache_follows_structural_changes(T)
    local world = World.new()
    local a = world:spawn({Position = C.Position(0, 0)})
    local before = world:query("Position", "Icon")
    T.eq(world:query("Position", "Icon"), before, "unchanged world reuses the cached array")
    T.list_eq(before, {})

    world:add(a, "Icon", C.Icon(1))
    T.list_eq(world:query("Position", "Icon"), {a})
    T.list_eq(before, {}, "an array handed out earlier is a snapshot")

    world:remove(a, "Icon")
    T.list_eq(world:query("Position", "Icon"), {})

    -- Changing data in place isn't structural and must not thrash the cache.
    local cached = world:query("Position")
    world:get(a, "Position").x = 5
    world:add(a, "Position", C.Position(6, 6))
    T.eq(world:query("Position"), cached)
end

function tests.destroy_is_deferred_to_the_end_of_the_step(T)
    local world = World.new()
    local seen = {}
    world:add_system({name = "reaper", query = {"Doomed"}, step = function(w, ids)
        for i=1, #ids do
            w:destroy(ids[i])
            table.insert(seen, w:get(ids[i], "Named").name) -- Still readable this step.
        end
    end})
    world:spawn({Doomed = true, Named = C.Named("a")})
    world:spawn({Doomed = true, Named = C.Named("b")})

    world:step(1/60)
    T.list_eq(seen, {"a", "b"})
    T.list_eq(world:query("Doomed"), {})
end

function tests.systems_run_in_order_and_only_when_they_match(T)
    local world = World.new()
    local ran = {}
    world:add_system({name = "first", query = {"A"}, step = function() table.insert(ran, "first") end})
    world:add_system({name = "second", query = {"B"}, step = function() table.insert(ran, "second") end})
    world:add_system({name = "third", query = {"A"}, step = function() table.insert(ran, "third") end})

    T.eq(world:has_active_systems(), false)
    world:step(1/60)
    T.list_eq(ran, {})

    world:spawn({A = true})
    T.eq(world:has_active_systems(), true)
    world:step(1/60)
    T.list_eq(ran, {"first", "third"})
end

function tests.events(T)
    local world = World.new()
    local got = {}
    world:on("ping", function(event) table.insert(got, event.n) end)
    world:on("ping", function(event) table.insert(got, event.n * 10) end)
    world:emit("ping", {n = 1})
    world:emit("nobody_listens", {})
    T.list_eq(got, {1, 10})
end

function tests.containment_keeps_things_in_exactly_one_place(T)
    local world = World.new()
    local hull = world:spawn({Position = C.Position(1, 2)})
    local thing = world:spawn({InCargo = C.InCargo(hull)})

    containment.to_world(world, thing, 3, 4)
    T.eq(world:has(thing, "InCargo"), false)
    T.eq(world:get(thing, "Position").x, 3)
    T.list_eq(containment.contents(world, hull), {})

    containment.to_cargo(world, thing, hull)
    T.eq(world:has(thing, "Position"), false)
    T.list_eq(containment.contents(world, hull), {thing})
end

function tests.new_game_hull(T)
    local world = new_game({x = 10, y = 10, frame_names = {"AA-111", "BB-222", "CC-333"}})

    -- Frames, three modules, and the radio exactly once.
    local names = {}
    local cargo = hull_queries.cargo(world)
    for i=1, #cargo do
        table.insert(names, world:get(cargo[i], "Named").name)
    end
    T.list_eq(names, {"AA-111", "BB-222", "CC-333", "EM FIELD GEN", "L. Comms Array", "Sleeper", "Radio"})

    T.eq(hull_queries.power_usage(world), 37)
    -- 3 frames carrying a relay each, plus the modules and the radio.
    T.near(hull_queries.cargo_tonnage(world), 3 * (0.2 + 0.02) + 0.8 + 0.8 + 5 + 0.002, 1e-9)
    T.eq(world:has_active_systems(), false, "a fresh world is idle")
end

return tests
