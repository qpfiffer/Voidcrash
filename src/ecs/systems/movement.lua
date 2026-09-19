-- Moves things along a straight line at Movement.speed world units per second.
local Utils = require("src/Utils")

local movement = {}

local ARRIVAL_EPSILON = 1e-9

movement.system = {
    name = "movement",
    query = {"Movement", "Position"},
    step = function(world, ids, dt)
        for i=1, #ids do
            local entity = ids[i]
            local move = world:get(entity, "Movement")
            local position = world:get(entity, "Position")

            local distance = Utils.dist(move.origin_x, move.origin_y, move.dest_x, move.dest_y)
            if distance < ARRIVAL_EPSILON then
                -- Already there. (This used to leave the order stuck forever.)
                move.progress = 1
            else
                move.progress = math.min(move.progress + move.speed * dt / distance, 1)
            end

            if move.progress >= 1 then
                position.x = move.dest_x
                position.y = move.dest_y
                world:remove(entity, "Movement")
                world:emit("arrived", {entity = entity})
            else
                position.x = Utils.lerp(move.origin_x, move.dest_x, move.progress)
                position.y = Utils.lerp(move.origin_y, move.dest_y, move.progress)
            end
        end
    end,
}

return movement
