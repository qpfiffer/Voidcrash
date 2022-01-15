local FrameObject = {}
FrameObject.__index = FrameObject

local constants = require("src/Constants")
local Utils = require("src/Utils")

local CollectorObject = require("src/objects/CollectorObject")
local ObjectType = require("src/objects/ObjectType")

local SPEED = 0.0002
local BASE_WEIGHT_TONS = 0.2

function FrameObject:init(name, x, y, dest_x, dest_y)
    local this = {
        object_type = ObjectType.DISPATCHABLE + ObjectType.CARGOABLE,
        speed = SPEED,
        ticks_advanced = SPEED,
        progress = 0,

        origin_x = x,
        origin_y = y,

        dest_x = dest_x,
        dest_y = dest_y,

        world_x = x,
        world_y = y,

        name = name,
        cargo_max = 2, -- Tons
        cargo = {},

        deployed = false,
    }
    setmetatable(this, self)

    return this
end

function FrameObject:get_object_type()
    return self.object_type
end

function FrameObject:get_x()
    return self.world_x
end

function FrameObject:set_x(val)
    --print("Setting X to " .. val)
    self.world_x = val
end

function FrameObject:get_y()
    return self.world_y
end

function FrameObject:set_y(val)
    --print("Setting Y to " .. val)
    self.world_y = val
end

function FrameObject:get_name()
    return self.name
end

function FrameObject:get_deployed()
    return self.deployed
end

function FrameObject:set_deployed(val)
    self.deployed = val
end

function FrameObject:deploy_with_destination(start_x, start_y, dest_x, dest_y)
    self.deployed = true
    self.origin_x = start_x
    self.origin_y = start_y
    self.world_x = start_x
    self.world_y = start_y
    self.dest_x = dest_x
    self.dest_y = dest_y
    print(self.name .. " has been deployed!")
end

function FrameObject:get_tonnage()
    local total_used = 0
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        total_used = total_used + cargo_item:get_tonnage()
    end

    return total_used + BASE_WEIGHT_TONS
end

function FrameObject:update(game_state, dt)
    if not self.deployed then
        return
    end

    local x_not_equal = self.world_x ~= self.dest_x
    local y_not_equal = self.world_y ~= self.dest_y
    if x_not_equal or y_not_equal then
        local distance = Utils.dist(self.origin_x, self.origin_y, self.dest_x, self.dest_y)
        self.progress = self.progress + (self.speed * 1/distance)

        if self.progress >= 1 then
            self.progress = 1
        end

        if x_not_equal then
            self:set_x(Utils.lerp(self.origin_x, self.dest_x, self.progress))
        end

        if y_not_equal then
            self:set_y(Utils.lerp(self.origin_y, self.dest_y, self.progress))
        end
    end
end

return FrameObject
