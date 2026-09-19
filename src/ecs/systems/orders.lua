-- Works through each entity's order queue, one order at a time.
local containment = require("src/ecs/containment")
local C = require("src/ecs/components")
local constants = require("src/Constants")
local Utils = require("src/Utils")

local orders = {}

orders.MOVEMENT = "movement"
orders.DROP = "drop"
orders.EMBARK = "embark"

-- Runs once when an order becomes the current one.
local start = {}
-- Runs every step after that; returns true when the order is finished.
local continue = {}

start[orders.MOVEMENT] = function(world, entity, order)
    local position = world:get(entity, "Position")
    world:add(entity, "Movement", C.Movement(
        position.x, position.y, order.dest_x, order.dest_y, constants.FRAME_SPEED))
end

continue[orders.MOVEMENT] = function(world, entity, order)
    -- The movement system removes Movement on arrival.
    return not world:has(entity, "Movement")
end

continue[orders.DROP] = function(world, entity, order)
    local item = containment.first_with(world, entity, "Deployable")
    if not item then
        world:emit("drop_failed", {entity = entity})
        return true
    end

    local position = world:get(entity, "Position")
    containment.to_world(world, item, position.x, position.y)
    world:emit("item_deployed", {entity = entity, item = item})
    return true
end

continue[orders.EMBARK] = function(world, entity, order)
    local hull = world.res.hull
    local position = world:get(entity, "Position")
    local hull_position = world:get(hull, "Position")
    local distance = Utils.dist(position.x, position.y, hull_position.x, hull_position.y)
    if distance > constants.EMBARK_RADIUS then
        world:emit("embark_failed", {entity = entity})
        return true
    end

    -- Whatever else was queued doesn't survive being stowed.
    containment.to_cargo(world, entity, hull)
    world:remove(entity, "Orders")
    world:emit("embarked", {entity = entity})
    return true
end

orders.system = {
    name = "orders",
    query = {"Orders", "Position"},
    step = function(world, ids, dt)
        for i=1, #ids do
            local entity = ids[i]
            local component = world:get(entity, "Orders")

            if not component.current and #component.queue > 0 then
                component.current = table.remove(component.queue, 1)
                world:emit("order_started", {entity = entity, kind = component.current.kind})
                if start[component.current.kind] then
                    start[component.current.kind](world, entity, component.current)
                end
            end

            if component.current and continue[component.current.kind](world, entity, component.current) then
                component.current = nil
            end

            -- Nothing left to do: stop asking to be simulated. (Embarking has
            -- already removed the component.)
            if world:get(entity, "Orders") == component and not component.current and #component.queue == 0 then
                world:remove(entity, "Orders")
            end
        end
    end,
}

return orders
