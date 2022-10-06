local PlayerInfo = {}
PlayerInfo.__index = PlayerInfo

local bit = require("src/vendor/bitop-funcs")

local constants = require("src/Constants")

local FrameObject = require("src/objects/FrameObject")
local ObjectType = require("src/objects/ObjectType")
local RelayObject = require("src/objects/RelayObject")

local SlimeMold = require("src/entities/SlimeMold")

local EMFieldObject = require("src/objects/hull/EMFieldObject")
local LatticeCommunicationsArrayObject = require("src/objects/hull/LatticeCommunicationsArray")
local RadioObject = require("src/objects/RadioObject")
local SleeperObject = require("src/objects/hull/SleeperObject")

local Utils = require("src/Utils")

function PlayerInfo:init()
    local this = {
        hull_name = "TH-51US",

        cur_tick = math.random(constants.GENESIS),

        overmap_x = math.random(constants.OVERMAP_MAX_X),
        overmap_y = math.random(constants.OVERMAP_MAX_Y),

        world_objects = {},
        cargo = {},

        radio = RadioObject:init(),

        full_power = constants.MAX_POWER,
        powered_on = {
            EMFieldObject:init(),
            LatticeCommunicationsArrayObject:init(),
            SleeperObject:init(),
        },

        current_lattice_step = 1,
    }

    this.cargo = {
        FrameObject:init(Utils.generate_frame_name(),
            this.overmap_x, this.overmap_y,
            math.random(constants.OVERMAP_MAX_X), math.random(constants.OVERMAP_MAX_Y)),
        FrameObject:init(Utils.generate_frame_name(),
            this.overmap_x, this.overmap_y,
            math.random(constants.OVERMAP_MAX_X), math.random(constants.OVERMAP_MAX_Y)),
        FrameObject:init(Utils.generate_frame_name(),
            this.overmap_x, this.overmap_y,
            math.random(constants.OVERMAP_MAX_X), math.random(constants.OVERMAP_MAX_Y)),
    }

    this.world_objects = {
        --SlimeMold:init(this.overmap_x + 0.1, this.overmap_y, nil, true)
    }

    table.insert(this.powered_on, this.radio)

    setmetatable(this, self)
    return this
end

function PlayerInfo:get_power_items()
    return self.powered_on
end

function PlayerInfo:get_world_objects()
    return self.world_objects
end

function PlayerInfo:add_world_object(object)
    table.insert(self.world_objects, object)
end

function PlayerInfo:get_cargo()
    return self.cargo
end

function PlayerInfo:has_dispatchable()
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        if bit.band(cargo_item.object_type, ObjectType.DISPATCHABLE) == ObjectType.DISPATCHABLE then
            return true
        end
    end

    return false
end

function PlayerInfo:_get_objects_of_type(from, object_type)
    local to_return = {}
    for i in pairs(from) do
        local item = from[i]
        if bit.band(item:get_object_type(), object_type) == object_type then
            table.insert(to_return, item)
        end
    end

    return to_return
end

function PlayerInfo:get_world_objects_of_type(object_type)
    return self:_get_objects_of_type(self.world_objects, object_type)
end

function PlayerInfo:get_cargo_items_of_type(object_type)
    return self:_get_objects_of_type(self.cargo, object_type)
end

function PlayerInfo:pop_item_from_cargo_of_type(object_type)
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        if bit.band(cargo_item.object_type, object_type) == object_type then
            table.remove(self.cargo, i)
            print(#self.cargo)
            return cargo_item
        end
    end

    return nil
end

function PlayerInfo:get_power_usage()
    local total_used = 0
    for i in pairs(self.powered_on) do
        local active_power_item = self.powered_on[i]
        total_used = total_used + active_power_item:get_power_usage()
    end

    return total_used
end

function PlayerInfo:get_cargo_usage()
    local total_used = 0
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        total_used = total_used + cargo_item:get_tonnage()
    end

    return total_used
end

function PlayerInfo:get_current_lattice_step()
    return self.current_lattice_step
end

function PlayerInfo:set_current_lattice_step(val)
    self.current_lattice_step = val
end

function PlayerInfo:get_lattice_intensity(world_x, world_y)
    -- Returns the value of the lattice, (0 - 1000), for an x/y pair.
    local _world_x = world_x + constants.LATTICE_NOISE_OFFSET_X
    local _world_y = world_y + constants.LATTICE_NOISE_OFFSET_Y
    local raw_noise_val = love.math.noise(world_x, world_y, self.current_lattice_step)
    local noise_val = math.floor(raw_noise_val * 1000)

    return noise_val
end

return PlayerInfo
