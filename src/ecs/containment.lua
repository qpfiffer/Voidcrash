-- The only code allowed to move things between "in the world" and "inside
-- something". Keeping it here is what guarantees an entity is never in two
-- places (the old cargo lists managed to hold the radio twice).
local C = require("src/ecs/components")

local containment = {}

function containment.to_world(world, entity, x, y)
    world:remove(entity, "InCargo")
    world:add(entity, "Position", C.Position(x, y))
end

function containment.to_cargo(world, entity, container)
    world:remove(entity, "Position")
    world:remove(entity, "Movement")
    world:add(entity, "InCargo", C.InCargo(container))
end

-- Everything directly inside `container`, oldest first.
function containment.contents(world, container)
    local found = {}
    local carried = world:query("InCargo")
    for i=1, #carried do
        if world:get(carried[i], "InCargo").of == container then
            table.insert(found, carried[i])
        end
    end
    return found
end

-- The first thing inside `container` that has `component`, or nil.
function containment.first_with(world, container, component)
    local contents = containment.contents(world, container)
    for i=1, #contents do
        if world:has(contents[i], component) then
            return contents[i]
        end
    end
    return nil
end

return containment
