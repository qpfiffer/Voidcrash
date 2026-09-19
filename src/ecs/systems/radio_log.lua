-- Turns what happens in the world into the lines shown on the radio tab.
-- Nothing else writes to the log; the simulation just emits events.
local orders = require("src/ecs/systems/orders")

local radio_log = {}

local ORDER_STARTED = {
    [orders.MOVEMENT] = " begins to move.",
    [orders.DROP] = " will dispatch next available item.",
    [orders.EMBARK] = " will rejoin the hull.",
}

function radio_log.write(world, message)
    local log = world:get(world.res.radio, "RadioLog")
    table.insert(log.messages, message)
    while #log.messages > log.max do
        table.remove(log.messages, 1)
    end
    world:emit("radio_message", {message = message})
end

function radio_log.install(world)
    local function name_of(entity)
        return world:get(entity, "Named").name
    end

    world:on("order_added", function(event)
        radio_log.write(world, name_of(event.entity) .. " is following new order.")
    end)
    world:on("order_started", function(event)
        radio_log.write(world, name_of(event.entity) .. ORDER_STARTED[event.kind])
    end)
    world:on("arrived", function(event)
        radio_log.write(world, name_of(event.entity) .. " has arrived at destination.")
    end)
    world:on("item_deployed", function(event)
        radio_log.write(world, name_of(event.entity) .. " has deployed " .. name_of(event.item))
    end)
    world:on("drop_failed", function(event)
        radio_log.write(world, name_of(event.entity) .. " has nothing to deploy.")
    end)
    world:on("embarked", function(event)
        radio_log.write(world, name_of(event.entity) .. " has rejoined the hull.")
    end)
    world:on("embark_failed", function(event)
        radio_log.write(world, name_of(event.entity) .. " is too far from the hull to rejoin.")
    end)
end

return radio_log
