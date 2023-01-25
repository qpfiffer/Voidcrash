local LatticeCommunicationsArrayObject = {}
LatticeCommunicationsArrayObject.__index = LatticeCommunicationsArrayObject

local constants = require("src/Constants")
local ObjectType = require("src/objects/ObjectType")

function LatticeCommunicationsArrayObject:init(initial_state)
    local this = {
        power_usage = 10,
        object_type = ObjectType.BASE
    }
    setmetatable(this, self)

    return this
end

function LatticeCommunicationsArrayObject:get_name()
    return "L. Comms Array"
end

function LatticeCommunicationsArrayObject:get_power_usage()
    return self.power_usage
end

function LatticeCommunicationsArrayObject:get_tonnage()
    return 0.8
end

function LatticeCommunicationsArrayObject:get_object_type()
    return self.object_type
end

return LatticeCommunicationsArrayObject
