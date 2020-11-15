local SleeperObject = {}
SleeperObject.__index = SleeperObject

local constants = require("src/Constants")

function SleeperObject:init(initial_state)
    local this = {
        power_usage = 10,
    }
    setmetatable(this, self)

    return this
end

function SleeperObject:get_power_usage()
    return self.power_usage
end

return SleeperObject
