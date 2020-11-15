local PlayerInfo = {}
PlayerInfo.__index = PlayerInfo

local constants = require("src/Constants")

local EMFieldObject = require("src/objects/hull/EMFieldObject")
local SleeperObject = require("src/objects/hull/SleeperObject")

function PlayerInfo:init()
    local this = {
        ship_name = "AZM-12",

        cur_tick = math.random(constants.GENESIS),

        overmap_x = math.random(constants.OVERMAP_MAX_X),
        overmap_y = math.random(constants.OVERMAP_MAX_Y),

        local_x = math.random(constants.LOCALMAP_MAX_X),
        local_y = math.random(constants.LOCALMAP_MAX_Y),

        full_power = constants.MAX_POWER,
        powered_on = {
            SleeperObject:init(),
            EMFieldObject:init(),
        },
    }
    setmetatable(this, self)

    return this
end

function PlayerInfo:get_power_usage()
    local total_used = 0
    for i in pairs(self.powered_on) do
        local active_power_item = self.powered_on[i]
        total_used = total_used + active_power_item:get_power_usage()
    end

    return total_used
end

return PlayerInfo
