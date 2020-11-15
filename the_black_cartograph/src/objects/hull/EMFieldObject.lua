local EMFieldObject = {}
EMFieldObject.__index = EMFieldObject

local constants = require("src/Constants")

function EMFieldObject:init(initial_state)
    local this = {
        power_usage = 15,
    }
    setmetatable(this, self)

    return this
end

function EMFieldObject:get_power_usage()
    return self.power_usage
end

return EMFieldObject
