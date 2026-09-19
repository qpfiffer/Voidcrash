-- What the map's context menu offers for a thing in the world. This is UI: it
-- looks at an entity's components to decide what makes sense, and turns choices
-- into commands. The entities themselves know nothing about menus.
local commands = require("src/sim/commands")
local containment = require("src/ecs/containment")

local context_actions = {}

-- Menu items for `entity`, acting on the map position (target_x, target_y).
-- `done` is called after any of them fires. Things that can't do anything
-- (a relay, say) simply get no items.
function context_actions.for_entity(world, entity, target_x, target_y, done)
    local items = {}

    if world:has(entity, "Frame") then
        local deployed = world:has(entity, "Position")

        table.insert(items, {
            name = "Drop Item",
            enabled = deployed and containment.first_with(world, entity, "Deployable") ~= nil,
            callback = function()
                commands.drop(world, entity)
                done()
            end,
        })
        table.insert(items, {
            name = "Move",
            enabled = deployed,
            callback = function()
                commands.move(world, entity, target_x, target_y)
                done()
            end,
        })
        table.insert(items, {
            name = "Return to Hull",
            enabled = deployed,
            callback = function()
                commands.return_to_hull(world, entity)
                done()
            end,
        })
    end

    return items
end

return context_actions
