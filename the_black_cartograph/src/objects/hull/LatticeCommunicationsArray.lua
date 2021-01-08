local LatticeCommunicationsArrayObject = {}
LatticeCommunicationsArrayObject.__index = LatticeCommunicationsArrayObject

local constants = require("src/Constants")

function LatticeCommunicationsArrayObject:init(initial_state)
    local this = {
        power_usage = 10,
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

return LatticeCommunicationsArrayObject
