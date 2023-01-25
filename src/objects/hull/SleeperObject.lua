local SleeperObject = {}
SleeperObject.__index = SleeperObject

local constants = require("src/Constants")
local ObjectType = require("src/objects/ObjectType")

function SleeperObject:init(initial_state)
    local this = {
        power_usage = 10,
        object_type = ObjectType.BASE
    }
    setmetatable(this, self)

    return this
end

function SleeperObject:get_name()
    return "Sleeper"
end

function SleeperObject:get_power_usage()
    return self.power_usage
end

function SleeperObject:get_tonnage()
    return 5
end

function SleeperObject:get_object_type()
    return self.object_type
end

return SleeperObject
