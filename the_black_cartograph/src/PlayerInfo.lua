local PlayerInfo = {}
PlayerInfo.__index = PlayerInfo

local constants = require("src/Constants")

function PlayerInfo:init()
    local this = {
        ship_name = "AZM-12",

        cur_tick = math.random(constants.GENESIS),

        overmap_x = math.random(constants.OVERMAP_MAX_X),
        overmap_y = math.random(constants.OVERMAP_MAX_Y),

        local_x = math.random(constants.LOCALMAP_MAX_X),
        local_y = math.random(constants.LOCALMAP_MAX_Y),
    }
    setmetatable(this, self)

    return this
end

return PlayerInfo
