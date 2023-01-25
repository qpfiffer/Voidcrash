local EMFieldObject = {}
EMFieldObject.__index = EMFieldObject

local constants = require("src/Constants")

local ObjectType = require("src/objects/ObjectType")

function EMFieldObject:init(initial_state)
    local this = {
        power_usage = 15,
        object_type = ObjectType.BASE
    }
    setmetatable(this, self)

    return this
end

function EMFieldObject:get_name()
    return "EM FIELD GEN"
end

function EMFieldObject:get_power_usage()
    return self.power_usage
end

function EMFieldObject:get_tonnage()
    return 0.8
end

function EMFieldObject:get_object_type()
    return self.object_type
end

return EMFieldObject
