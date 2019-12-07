local PlayerInfo = {}
PlayerInfo.__index = PlayerInfo

function PlayerInfo:init()
    local this = {
        ship_name = "AZM-12",
    }
    setmetatable(this, self)

    return this
end

return PlayerInfo
