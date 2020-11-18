local FrameObject = {}
FrameObject.__index = FrameObject

local constants = require("src/Constants")

local SPEED = 0.0002

function _lerp(a, b, t)
    return a * (1-t) + b * t
end

function _dist(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

function FrameObject:init(x, y, dest_x, dest_y)
    local this = {
        speed = SPEED,

        ticks_advanced = SPEED,

        progress = 0,

        origin_x = x,
        origin_y = y,

        dest_x = dest_x,
        dest_y = dest_y,

        world_x = x,
        world_y = y,
    }
    setmetatable(this, self)

    return this
end

function FrameObject:get_x()
    return self.world_x
end

function FrameObject:set_x(val)
    self.world_x = val
end

function FrameObject:get_y()
    return self.world_y
end

function FrameObject:set_y(val)
    self.world_y = val
end

function FrameObject:get_name()
    return "Frame"
end

function FrameObject:update(game_state, dt)
    if self.world_x ~= self.dest_x and self.world_y ~= self.dest_y then
        local distance = _dist(self.world_x, self.world_y, self.dest_x, self.dest_y)
        self.progress = self.progress + (self.speed * 1/distance)

        if self.progress >= 1 then
            self.progress = 1
        end
        self:set_x(_lerp(self.origin_x, self.dest_x, self.progress))
        self:set_y(_lerp(self.origin_y, self.dest_y, self.progress))
    end
end

return FrameObject
