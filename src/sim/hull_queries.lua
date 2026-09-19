-- Read-only questions about the hull and what's in it.
local containment = require("src/ecs/containment")

local hull_queries = {}

-- Own mass plus everything carried, recursively.
function hull_queries.tonnage(world, entity)
    local mass = world:get(entity, "Mass")
    local total = mass and mass.tons or 0

    local contents = containment.contents(world, entity)
    for i=1, #contents do
        total = total + hull_queries.tonnage(world, contents[i])
    end
    return total
end

function hull_queries.cargo(world)
    return containment.contents(world, world.res.hull)
end

function hull_queries.cargo_tonnage(world)
    local total = 0
    local cargo = hull_queries.cargo(world)
    for i=1, #cargo do
        total = total + hull_queries.tonnage(world, cargo[i])
    end
    return total
end

-- Everything installed in the hull that draws power.
function hull_queries.powered(world)
    local powered = {}
    local cargo = hull_queries.cargo(world)
    for i=1, #cargo do
        if world:has(cargo[i], "Powered") then
            table.insert(powered, cargo[i])
        end
    end
    return powered
end

function hull_queries.power_usage(world)
    local total = 0
    local powered = hull_queries.powered(world)
    for i=1, #powered do
        total = total + world:get(powered[i], "Powered").usage
    end
    return total
end

return hull_queries
