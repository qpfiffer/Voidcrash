local CollectorObject = {}
CollectorObject.__index = CollectorObject

local constants = require("src/Constants")

function CollectorObject:init(x, y)
    local this = {
        object_type = ObjectType.DEPLOYABLE + ObjectType.CARGOABLE,
        speed = SPEED,

        ticks_advanced = SPEED,

        world_x = x,
        world_y = y,
    }
    setmetatable(this, self)

    return this
end

function CollectorObject:get_x()
    return self.world_x
end

function CollectorObject:set_x(val)
    self.world_x = val
end

function CollectorObject:get_y()
    return self.world_y
end

function CollectorObject:set_y(val)
    self.world_y = val
end

function CollectorObject:get_name()
    return "Collector"
end

function CollectorObject:update(game_state, dt)
end

return CollectorObject
