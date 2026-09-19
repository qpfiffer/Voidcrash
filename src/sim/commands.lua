-- Everything the player can tell the world to do. The UI calls these; it never
-- pokes at components itself.
local C = require("src/ecs/components")
local containment = require("src/ecs/containment")
local orders = require("src/ecs/systems/orders")

local commands = {}

-- Only things out in the world take orders. Returns whether it was accepted.
local function _add_order(world, entity, order)
    if not world:alive(entity) or not world:has(entity, "Position") then
        return false
    end

    local component = world:get(entity, "Orders") or world:add(entity, "Orders", C.Orders())
    table.insert(component.queue, order)
    world:emit("order_added", {entity = entity, kind = order.kind})
    return true
end

function commands.move(world, entity, x, y)
    return _add_order(world, entity, {kind = orders.MOVEMENT, dest_x = x, dest_y = y})
end

function commands.drop(world, entity)
    return _add_order(world, entity, {kind = orders.DROP})
end

function commands.return_to_hull(world, entity)
    local hull_position = world:get(world.res.hull, "Position")
    return commands.move(world, entity, hull_position.x, hull_position.y)
        and _add_order(world, entity, {kind = orders.EMBARK})
end

function commands.can_dispatch(world)
    return containment.first_with(world, world.res.hull, "Dispatchable") ~= nil
end

-- Sends the next available dispatchable thing in the hull out to (x, y).
-- Returns the entity, or nil if the hold has nothing to send.
function commands.dispatch(world, x, y)
    local hull = world.res.hull
    local entity = containment.first_with(world, hull, "Dispatchable")
    if not entity then
        return nil
    end

    local hull_position = world:get(hull, "Position")
    containment.to_world(world, entity, hull_position.x, hull_position.y)
    commands.move(world, entity, x, y)
    return entity
end

return commands
