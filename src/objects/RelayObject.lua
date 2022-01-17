local RelayObject = {}
RelayObject.__index = RelayObject

local constants = require("src/Constants")
local Utils = require("src/Utils")

local ObjectType = require("src/objects/ObjectType")
local OrderType = require("src/management/OrderType")

local BASE_WEIGHT_TONS = 0.02

function RelayObject:init(name, x, y, deployed)
    local this = {
        object_type = ObjectType.CARGOABLE,

        world_x = x,
        world_y = y,

        name = name,

        messages_in = {},
        messages_out = {},

        deployed = deployed,
    }
    setmetatable(this, self)

    return this
end

function RelayObject:get_object_type()
    return self.object_type
end

function RelayObject:get_x()
    return self.world_x
end

function RelayObject:set_x(val)
    self.world_x = val
end

function RelayObject:get_y()
    return self.world_y
end

function RelayObject:set_y(val)
    self.world_y = val
end

function RelayObject:get_name()
    return self.name
end

function RelayObject:get_icon()
    return 8
end

function RelayObject:get_tonnage()
    return BASE_WEIGHT_TONS
end

function RelayObject:get_deployed()
    return self.deployed
end

function RelayObject:set_deployed(val)
    self.deployed = val
end

function RelayObject:update(game_state, dt)
    if not self.deployed then
        return
    end
end

return RelayObject
